#!/bin/bash

echo "$1 $2 $3 $4" >> /fan_control/log.txt
#
# This Cmd4 example demonstrates a script that is compatible with
# cmdSwitch2's example of controlling a PS4.
#
# Your Cmd4 .homebridge/.config.json file would have a state_cmd like:
# state_cmd: ".homebridge/Cmd4Scripts/Examples/PS4.sh"
#
# Testing from the shell prompt:
#    ./PS4.sh Get PS4 On
#    or
#    ./PS4.sh Set PS4 On 1
#    or
#    ./PS4.sh Set PS4 On 0

# Exit immediately if a command exits with a non-zero status
set -e

# Check if the first parameter to this script was "Get" for getting an accessory's
# specific attribute.
if [ "$1" = "Get" ]; then
	read value < "/fan_control/state/$2_$3"
	echo "$value"
   # Normally we would exit immediately if a command fails with a non-zero status.
   # In this case ps4-waker can fail and we would rely on the failing exit status to
   # tell Cmd4 that the accessory is not on the network. That would be the prefered
   # thing to do. However for this example we are going to output '0' (false) so
   # that you can see the '0' on the console telling us that the accessory is not
   # on the network.
   #set +e

   #ps4-waker search | grep -i '200 Ok' >> /dev/null 2>&1
   #rc=$?

   # Exit immediately if a command exits with a non-zero status
   #set -e

   # Check if we got the message '200 OK' meaning the accessory is
   # on the network by seeing if the return code of the above command passed or
   # failed.
   #if [ "$rc" = "0" ]; then
      # The message was recieved so the target is up, sending a '1' (true), like
      # a binary number is, back to Cmd4.
      #echo "1"

      # Exit this script positivitely.
      exit 0
  # else
      # The message was not recieved so the target must be down, sending a '0' (false), like
      # a binary number is, back to Cmd4.
      #echo "0"

      # Exit this script positivitely, even though ps4-waker failed.
      #exit 0
   #fi
fi

# Check if the first parameter to this script was "Set" for setting an accessory's
# specific attribute.
if [ "$1" = "Set" ]; then

   # $2 would be the name of the accessory.
   # $3 would be the accessory's charactersistic 'On'.
   # $4 would be '1' for 'On' and '0' for 'Off', like a binary number is.
   # $4 would be 'true' for 'On' and 'false' for 'Off' with
   # outputConstants=true in your .homebridge/.config.json file.

        if [ "$2" = "FR_FAN_1" ]; then
                sleep .2
		remote=1
        else
                remote=2
		sleep .8
        fi

   # Handle the Set 'On' attribute of the accessory
   if [ "$3" = "On" ]; then
	read value < "/fan_control/state/$2_$3"
	if [ "$4" = $value ]; then
		exit 0
	fi
      # If the accessory is to be set on
      if [ "$4" = "false" ]; then
         set +e

         # Execute the on command, set to speed 3 by default
         /fan_control/fan_send2 POWER $remote #>> /dev/null 2>&1

         # keep the result of the on/off command
         rc=$?

         # Exit immediately if a command exits with a non-zero status
         set -e
      else
         set +e
	# read the last set speed
	read speed < "/fan_control/state/$2_RotationSpeed"
	/fan_control/fan_control.sh Set $2 'RotationSpeed' $speed
         # Execute the on command, set to speed 3 by default
         #/fan_control/fan_send2 3 $remote #>> /dev/null 2>&1

         # keep the result of the on/off command
         rc=$?

         # Exit immediately if a command exits with a non-zero status
         set -e
      fi

      # Check if the on/off command had a positive return status.
      if [ "$rc" = "0" ]; then
	echo "$4" > "/fan_control/state/$2_$3"
         # The on/off command was successful, so exit successfully.
         exit 0

      else
         # The on/off comand had a failure result. Exit with that result.

         # Exit this script positivitely, even though ping failed.
         exit $rc
      fi
   # Handle the Set 'On' attribute of the accessory
   elif [ "$3" = "RotationSpeed" ]; then

      # If the accessory is to be set on
      if [ "$4" = "0"  ]; then
		speed="POWER"
	elif [ "$4" -lt "17" ]; then
		speed=1
	elif [ "$4" -lt "34" ]; then
		speed=2
	elif [ "$4" -lt "51" ]; then
		speed=3
        elif [ "$4" -lt "68" ]; then 
                speed=4
        elif [ "$4" -lt "85" ]; then 
                speed=5 
	else
		speed=6 
      fi
	set +e

         # Execute the on command, set to speed 3 by default
         /fan_control/fan_send2 $speed $remote #>> /dev/null 2>&1

         # keep the result of the on/off command
         rc=$?

         # Exit immediately if a command exits with a non-zero status
         set -e

      # Check if the on/off command had a positive return status.
      if [ "$rc" = "0" ]; then
	echo "$4" > "/fan_control/state/$2_$3"
         # The on/off command was successful, so exit successfully.
         exit 0

      else
         # The on/off comand had a failure result. Exit with that result.

         # Exit this script positivitely, even though ping failed.
         exit $rc
      fi
   # Handle the Set 'On' attribute of the accessory
   elif [ "$3" = "RotationDirection" ]; then

         set +e

         # Execute the on command, set to speed 3 by default
         /fan_control/fan_send2 REVERSE $remote #>> /dev/null 2>&1

         # keep the result of the on/off command
         rc=$?

         # Exit immediately if a command exits with a non-zero status
         set -e

      # Check if the on/off command had a positive return status.
      if [ "$rc" = "0" ]; then
	echo "$4" > "/fan_control/state/$2_$3"
         # The on/off command was successful, so exit successfully.
         exit 0

      else
         # The on/off comand had a failure result. Exit with that result.

         # Exit this script positivitely, even though ping failed.
         exit $rc
      fi
   fi
fi

# The proper arguments to this script were not passed to it so end with a failure exit status.
exit 666
