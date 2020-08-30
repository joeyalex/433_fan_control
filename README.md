# 433_fan_control
Control szfunpower 6 speed RF ceiling fans with RPi!
![Controller](/images/controller.jpg)

# What is this all about?
I have a pair of ceiling fans that use szfunpower FC989RS-B controllers. They have no pull chains, and are completely dependent on the remotes. They are also both in the same room, so having two remotes to control them seemed...less than ideal.

I wanted to integrate them with my existing home automation systems, but didn't find anything that seemed like it would work out of the box. Let the hacking commence!

# Step 1: Figure out the RF Protocol
I'm not an RF hacker by any means, so there's probably a better way to do this. I used a few different tools to get a feel for what the RF signals from the remotes looked like:
* Generic 433mhz TX/RX units (https://www.amazon.com/gp/product/B086ZL8W1W)
* RTL-SDR receiver (https://www.amazon.com/gp/product/B011HVUEME)
* Raspberry Pi (Model 3b+ in my case)
* [rtl_433](https://github.com/merbanan/rtl_433)
* [pilight](https://pilight.org)
* [pigpio](http://abyz.me.uk/rpi/pigpio/)
* Some other various software that didn't work out

## Early Attempt
Initially, I needed to figure out what frequency these things were transmitting on. After some reading, it seemed that 315MHz and 433MHz were the most popular
for this kind of application. I took a guess and went for 433MHz. I purchased the RX/TX pair from Amazon, and started trying to sniff the protocol.
My first attempts were with some tools that I hoped would make this easy: 433Utils, pilight, rpi-rf. Unfortunately, none of these seemed to be able to pick up
the funky protocol these controllers use. Also, the cheap RX unit was less than ideal, it picked up quite a bit of noise.

## RTL-SDR FTW
I decided to upgrade the receiver end of my toolkit with a RTL-SDR receiver. This ended up being a huge breakthrough. I collected samples from the remote with the SDR,
and then analyzed them in Audacity. I was able to discover a few things about the RF protocol via this method:
* There are short high pulses, long high pulses, and a long low reset/sync period.
* The short high pulse is about 290us
* the long high pulse is about 860us (about 3x the short pulse)
* the reset period is about 4375us (about 15x the short pulse)
* there is some kind of header/preamble that is sent at the beginning of each command, most likely to allow the gain to adjust on the receiver
* the header is 32 bits and the command is 33bits
* the first 2 bytes are the command and the second two bytes + 1 bit are fixed for each remote, and appear to be a remote ID of some sort

![Wave](/images/wave.png)

I also used 433_rtl, which made the process pretty easy. An example of the output from it:

    Attempting demodulation... short_width: 320, long_width: 908, reset_limit: 4448, sync_width: 0 
    Use a flex decoder with -X 'n=name,m=OOK_PWM,s=320,l=908,r=4448,g=888,t=232,y=0'
    pulse_demod_pwm(): Analyzer Device
    bitbuffer:: Number of rows: 5 
    [00] {32} fb fa 2c 67    : 11111011 11111010 00101100 01100111 
    [01] {33} fd fd 16 33 80 : 11111101 11111101 00010110 00110011 1
    [02] {33} fd fd 16 33 80 : 11111101 11111101 00010110 00110011 1
    [03] {33} fd fd 16 33 80 : 11111101 11111101 00010110 00110011 1
    [04] {33} fd fd 16 33 80 : 11111101 11111101 00010110 00110011 1

The "header" is basically the same as the command, however it is "shifted" left by one value, so we loose the first 1 in the above case, and end up with an even 32-bits.
The command is a little funky at 33-bits. I'm not sure if the 1 at the end is meant to be a parity bit, or what. (Most likely is, and it was 1 for every command I sniffed between both remotes.)

I found that the first 16 bits change with different button presses, and the last ones only changed when I switched to the other remote.

Between this and Audacity, I had a pretty good idea of what the commands looked like. Unfortunately, I was unable to get some of the already made
transmitting software to send these commands. I had near success with pilight-send and the raw protocol, but it had a hardcoded repeat value that made
the receiver react to each command twice. (This was fine, except for the "reverse" command.) I almost stuck with this, but wanted to get it all working.

# Step 2: Generating a Custom Waveform with Raspberry Pi
Since the off the shelf tools were struggling with the protocol, I determined I was going to have to create custom waveforms by controlling the timings.
I was actually able to get some level of functionality with pilight-send, but needed more control over the signal to get it working perfectly.

Example of the wave:

     __        ______    __
    | 1|      |  0   |  | 1|
    |  |______|      |__|  |______
    290   860    860 290 290 860
    

In order to get tis working, I collected all of the commands from both remotes with rtl_433. I then broke down the "commands" and the "Remote ID".
Then, I created a (really ugly!) C++ program that would take the raw command and remote ID, and build a wave of pulses to emulate the remote.
I decided to define the command as the first 16 bits, excluding the "header". (i.e. for the above example from rtl_433, the command is: 11111101 11111101)

### Commands:
Command|Code
-------|----
Power|```1110111011101110```
1hr timer|```1111001111110011```
4hr timer|```1111010111110101```
8hr timer|```1111001011110010```
Temperature?|```1111000111110001```
Breeze/Wind|```1111000011110000```
Speed 1|```1111110111111101```
Speed 2|```1111110011111100```
Speed 3|```1111101111111011```
Speed 4|```1111101011111010```
Speed 5|```1111100111111001```
Speed 6|```1111100011111000```
Reverse|```1111011011110110```
Light On|```1111111111111111```
Light Off|```1111111011111110```

### Pulse Definitions:
bit|pulse
---|-----
0|860us high, 290us low
1|290us high, 860us low
2/sync|290us high, 4375us low

The remote ID was kind of strange, because I wasn't sure what to do with the trailing bit. It seemed like it was just a parity bit, but it appeared
to be significant in the header...although I'm not fully convinced that the header is all that important, it might just be junk that's not quite a proper
command to tune the receiver. In fact, there's a bug in the program that doesn't match the wave from the remote exactly, and neither receiver seems to care.

I ended up defining the Remote ID as the last 17 bits, also from the second message, again ignoring the header.

The program takes the commands and remote ID, and strings them together. It creates the header by throwing out the first bit and attaching the full remote ID, then a rest/sync pulse.
It then sends the command twice. To build the command, it takes the full command string, and then cuts off the last bit of the remote ID, and attaches a rest/sync pulse.

If you want to use this for your own fan controller, you'll need to sniff the "remote ID", and also verify the commands are the same as the definitions. Once you know the remote ID, just plug that in to the define statement for REMOTE1.
Then, you should be able to control the fan like this:
>sudo ./fan-send POWER

I'll try to add some more information down the line. I still have some work to do, as I need to interface this with the rest of my home automation stuff now, as sshing into my RPi to tuen the fans off
is not any better than trying to keep track of two remotes!
