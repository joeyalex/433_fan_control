/*
   fan_send.cpp

   g++ -o fan_send fan_send.c -lpigpio -lrt -lpthread

   sudo ./fan_send command remoteID
*/

#include <stdio.h>
#include <string>
using namespace std;
#include <iostream>
#include <pigpio.h>
#include <unistd.h>
#include <sys/types.h>

#define GPIO 17
#define SHORT_PULSE 290;
#define LONG_PULSE 860;
#define SYNC_PULSE 4375;

static int gpio = GPIO;
static int shortPulse = SHORT_PULSE;
static int longPulse = LONG_PULSE;
static int syncPulse = SYNC_PULSE;

// Commands
#define POWER 		"1110111011101110"
#define	ONEHOUR 	"1111001111110011"
#define FOURHOUR  	"1111010111110101"
#define EIGHTHOUR	"1111001011110010"
#define THERMO		"1111000111110001"
#define WIND		"1111000011110000"
#define ONE		"1111110111111101"
#define TWO		"1111110011111100"
#define THREE		"1111101111111011"
#define	FOUR		"1111101011111010"
#define FIVE		"1111100111111001"
#define SIX		"1111100011111000"
#define REVERSE		"1111011011110110"
#define LIGHT_ON	"1111111111111111"
#define LIGHT_OFF	"1111111011111110"

#define REMOTE1 "00001101011011001"
#define REMOTE2 "00010110001100111"


string buildCommand(string const baseCommand, string const RemoteID) {
	/* command is defined as follows:
		baseCommand is the actual command, remote ID is the ID of the remote control.
		The actual code that is sent is as follows:
		preamble + remoteID (full thing)
		sync/reset = 2
		baseCommand + remoteID (chop off last digit)
		sync/reset = 2
		repeat command
		preamble is same as baseCommand with the first character discarded.
	*/
	
	string returnValue;
	returnValue += baseCommand.substr(1,baseCommand.length());
	returnValue += RemoteID;
	returnValue += "2";
	returnValue += baseCommand;
	returnValue += RemoteID.substr(0,RemoteID.length()-1);
	returnValue += "2";
        returnValue += baseCommand;
        returnValue += RemoteID.substr(0,RemoteID.length()-1);
        returnValue += "2";
        returnValue += baseCommand;
        returnValue += RemoteID.substr(0,RemoteID.length()-1);
        returnValue += "2";
        returnValue += baseCommand;
        returnValue += RemoteID.substr(0,RemoteID.length()-1);
        returnValue += "2";
        returnValue += baseCommand;
        returnValue += RemoteID.substr(0,RemoteID.length()-1);
        returnValue += "2";

	
	return returnValue;
	
}

void one(gpioPulse_t pulse[], int index) {
        //insert a one in the wave pulse.
        // short high pulse  + long low pulse
     pulse[index].gpioOn = (1<<gpio);
    pulse[index].gpioOff = 0;
    pulse[index].usDelay = shortPulse;
    pulse[index+1].gpioOn = 0;
    pulse[index+1].gpioOff = (1<<gpio);
    pulse[index+1].usDelay = longPulse;
}

void zero(gpioPulse_t pulse[], int index) {
        // send a zero, long high pulse + short low pulse
    pulse[index].gpioOn = (1<<gpio);
    pulse[index].gpioOff = 0;
    pulse[index].usDelay = longPulse;
    pulse[index+1].gpioOn = 0;
    pulse[index+1].gpioOff = (1<<gpio);
    pulse[index+1].usDelay = shortPulse;
}

void reset(gpioPulse_t pulse[], int index) {
        //reset is a short high pulse followed by reset/sync low
    pulse[index].gpioOn = (1<<gpio);
    pulse[index].gpioOff = 0;
    pulse[index].usDelay = shortPulse;
    pulse[index+1].gpioOn = 0;
    pulse[index+1].gpioOff = (1<<gpio);
    pulse[index+1].usDelay = syncPulse;
}

int main(int argc, char *argv[])
{
   int timeout = 10;
   int timeoutCount = 0;
   while (gpioInitialise() < 0)
   {
      if (timeoutCount >= timeout) {
	      fprintf(stderr, "pigpio initialisation failed\n");
	      return 1;
     }
      sleep(1);
      timeoutCount++;
   }
	string code;
	string command(argv[1]);
	string RemoteID;
	int remoteArg = atoi(argv[2]);
	if (argc > 2 && remoteArg == 2)  {
		RemoteID = REMOTE2;
	} else {
		RemoteID = REMOTE1;
	}

    	if ((command == "POWER")) {
		code = buildCommand(POWER,RemoteID);
	} else if (command == "1HR") {
		code = buildCommand(ONEHOUR, RemoteID);
	} else if (command == "4HR") {
		code = buildCommand(FOURHOUR, RemoteID);
	} else if (command == "8HR") {
		code = buildCommand(EIGHTHOUR, RemoteID);
	} else if (command == "THERMO") {
		code = buildCommand(THERMO, RemoteID);
	} else if (command == "WIND") {
		code = buildCommand(WIND, RemoteID);
	} else if (command == "1") {
		code = buildCommand(ONE, RemoteID);
	} else if (command == "2") {
		code = buildCommand(TWO, RemoteID);
	} else if (command == "3") {
		code = buildCommand(THREE, RemoteID);
	} else if (command == "4") {
		code = buildCommand(FOUR, RemoteID);
	} else if (command == "5") {
		code = buildCommand(FIVE, RemoteID);
	} else if (command == "6") {
		code = buildCommand(SIX, RemoteID);
	} else if (command == "REVERSE") {
		code = buildCommand(REVERSE, RemoteID);
	} else if (command == "LIGHT_ON") {
		code = buildCommand(LIGHT_ON, RemoteID);
	} else if (command == "LIGHT_OFF") {
		code = buildCommand(LIGHT_OFF, RemoteID);
	} else {
		cout<<"command undefined";
		return 1;
	}
	int wave_id;
	int numPulses = code.length()*2;
    	gpioPulse_t pulse[numPulses];
	int pulseArrIndex = 0;
    	gpioSetMode(gpio, PI_OUTPUT);

	for (int i = 0; i<code.length(); i++) {
		if (code[i] == '0') {
			zero(pulse, pulseArrIndex);
			pulseArrIndex += 2;
		} else if (code[i] == '1') {
			one(pulse, pulseArrIndex);
			pulseArrIndex += 2;
		} else if (code[i] == '2') {
			reset(pulse, pulseArrIndex);
			pulseArrIndex += 2;
		}
	}
	gpioWaveClear();
	gpioWaveAddNew();
    	gpioWaveAddGeneric(numPulses, pulse);

    	wave_id = gpioWaveCreate();
	if (wave_id >= 0)
	{
   		gpioWaveTxSend(wave_id, PI_WAVE_MODE_ONE_SHOT);
		while(gpioWaveTxBusy()) {
			sleep(0.5);
		}
   		gpioWaveTxStop();
	}
	else
	{
   	// Wave create failed.
	}

   /* Stop DMA, release resources */
   gpioTerminate();

   return 0;
}
