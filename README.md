# 433_fan_control
Control szfunpower 6 speed RF ceiling fans with RPi

# What is this all about?
I have a pair of ceiling fans that use szfunpower FC989RS-B controllers. They have no pull chains, and are completely dependent on the remotes. They are also both in the same room, so having two remotes to control them seemed...less than ideal.

I wanted to integrate them with my existing home automation systems, but didn't find anything that seemed like it would work out of the box. Let the hacking commence!

# Step 1: Figure out the RF Protocol
I'm not an RF hacker by any means, so there's probably a better way to do this. I used a few different tools to get a feel for what the RF signals from the remotes looked like:
* Generic 433mhz TX/RX units (https://www.amazon.com/gp/product/B086ZL8W1W)
* RTL-SDR receiver (https://www.amazon.com/gp/product/B011HVUEME)
* Raspberry Pi (Model 3b+ in my case)
* [rtl_433]https://github.com/merbanan/rtl_433
* [pilight]https://pilight.org
* [pigpio]http://abyz.me.uk/rpi/pigpio/
* Some other various software that didn't work out
