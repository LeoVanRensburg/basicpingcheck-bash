#!/bin/bash

# ping and curl must be installed for this script to work

# has a file so information can persist between multiple runs of this script
valuefile="./.environ"
if [ ! -f "$valuefile" ]; then
	declare -a ipFailedInRow=([0]=0 [1]=0 [2]=0 [3]=0 [4]=0 [5]=0 [6]=0 [7]=0)
	declare -a notifSent=([0]=0 [1]=0 [2]=0 [3]=0 [4]=0 [5]=0 [6]=0 [7]=0)
	declare -a numberOfRuns=0
else
	source $valuefile
fi

# has multiple arrays with corresponding ip's and names to associate the ip address with a location to send in telegram
ipToCheck=("IP-1" "IP-2" "IP-3" "IP-4" "IP-5" "IP-6" "IP-7")
nameToIP=("IP-1-Name" "IP-2-Name" "IP-3-Name" "IP-4-Name"
	"IP-5-Name" "IP-6-Name" "IP-7-Name")

for ip in "${!ipToCheck[@]}"
do
	pingResult=$(ping -c 1 ${ipToCheck[$ip]})
	if [[ $pingResult != *'64 bytes from'* ]]; then
		echo "Ping to ${nameToIP[$ip]} failed" 
		(( ipFailedInRow[$ip]++ ))

		# only send alert if ping has failed 3 times in a row, and a notification has not been previously sent
		if [[ ${ipFailedInRow[$ip]} -gt 2 && ${notifSent[$ip]} == 0 ]]; then
			timeDown="$((${ipFailedInRow[$ip]} * 5)) mins"
			curl -X POST \
     			-H 'Content-Type: application/json' \
			-d '{"chat_id": "telegramChatID", "text": "The'" ${nameToIP[$ip]} "'camera has been down for '"$timeDown"'. "disable_notification": false}' \
     			https://api.telegram.org/telegramBotID/sendMessage
			notifSent[$ip]=1
		fi
	else
		echo "Ping to ${nameToIP[$ip]} succeeded"
		ipFailedInRow[$ip]=0
		notifSent[$ip]=0
	fi
done

(( numberOfRuns++ ))
declare -p ipFailedInRow notifSent numberOfRuns > $valuefile
