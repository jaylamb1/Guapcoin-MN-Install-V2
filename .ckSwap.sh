#!/bin/bash
VPS=$(hostname)
FreeSwap=$(free -m | awk 'END{print}' | cut -c 40-44)
Message="*ALERT:* On $VPS, only $FreeSwap MB od free swap left"

if [[ "$FreeSwap" -lt 499 ]]; then

  curl -X POST -H 'Content-type: application/json' --data '{"text":"'"$Message"'"}' 

fi
