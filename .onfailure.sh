#!/bin/bash

VPS=$1
Service=$2

MN=$(systemctl | grep "$Service" | head -1 | awk '{ print $NF }')

Message="ALERT: On $VPS, $Service, $MN FAILED"

curl -X POST -H 'Content-type: application/json' --data '{"text":"'"$Message"'"}' https://hooks.slack.com/services/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
