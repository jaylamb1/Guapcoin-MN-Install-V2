#!/bin/bash

#VERSION 1.0 of the Report MN Status script

#Make all variable available as environment variables
set -a

#Print timestamp in Day Date(MM-DD-YYYY) Time(HH:MMam) Timezone format
#d_epoch=$(TZ=":US/Eastern" date +"%s")
d=$(TZ=":US/Eastern" date +"%s")
d_formatted=$(TZ=":US/Eastern" date -d @$d +'%a %m-%d-%Y %I:%M:%S%P EST')
d_filename=$(TZ=":US/Eastern" date -d @$d +'%a_%m-%d-%Y_%I:%M:%S%P_EST')

StatusReportFilename="/home/guapadmin/MN_Status/MN-Status-Report-$d_filename.txt"


echo "" | tee $StatusReportFilename
#Note: the tee command writes the onscreen report to a file also
echo "               [Masternode Status Report Rev 1.0]                " | tee $StatusReportFilename
echo "-----------------------------------------------------------------" | tee $StatusReportFilename

echo "Timestamp : $d_formatted" | tee $StatusReportFilename
echo "" | tee $StatusReportFilename
#echo "Test d: $d"

#Create arrays to hold GUAP addresses and address labels from file, and to store the MN statuses later on
declare -a MNArray
declare -a MNLabelArray
declare -a MNStatus

#capture the external file
filename=$1

#Clean up the file, remove bash comments and empty lines (creates a backup before removal)
sed -i".bkup" 's/^#.*$//' $filename #remove comments
sed -i '/^$/d' $filename #remove empty lines
#sed 's,\,,,g'

#While loop to read in each GUAP address and corresponding label
n=0
while read label address; do
# reading each line
MNLabelArray[$n]=$label
MNArray[$n]=$address
n=$((n+1))
done < $filename

LastGuapTime='0'
LastGuapTotal='0'

echo "" | tee $StatusReportFilename


echo "[Label]      [Address]                                [Subtotal] " | tee $StatusReportFilename
echo "-----------------------------------------------------------------" | tee $StatusReportFilename

echo "" | tee $StatusReportFilename

#For loop to get the current status each saved GUAP address and print out each address, with its label and its GUAP amount. Also send an alert through slack for that MN if the status is not "ENABLED"
n=0
for i in "${MNArray[@]}"
do
  tempLabel=${MNLabelArray[$n]}
  dir="/home/guapadmin/.guapcoin"

  if ! [[ $tempLabel == *M* ]]; then #Skip addresses that are not labeled as masternodes
    echo "  $tempLabel skipped because it is not a mastsernode" | tee $StatusReportFilename
    echo "" | tee $StatusReportFilename
  else
      if $(test -d $dir && echo true); then
          tempStatus=$(guapcoin-cli listmasternodes | grep -A1 \"status\" | grep -B1 \"$i\" | sed '$d' | sed 's/,//g' | sed 's/\"status\"://g' | sed 's/"//g' | sed 's/^[[:space:]]*//g')
      else
          tempStatus=$(guapcoin-cli -conf=/home/guapadmin/.guapcoin1/guapcoin.conf -datadir=/home/guapadmin/.guapcoin1 listmasternodes | grep -A1 \"status\" | grep -B1 \"$i\" | sed '$d' | sed 's/,//g' | sed 's/\"status\"://g' | sed 's/"//g' | sed 's/^[[:space:]]*//g')
      fi



      echo "  $tempLabel        $i     Status: $tempStatus" | tee $StatusReportFilename
      echo "" | tee $StatusReportFilename

      if ! [[ $tempStatus == "ENABLED" ]]; then

              server=$(hostname)
              status=$(guapcoin-cli listmasternodes | grep \"$i\" -A4 -B6 | sed '/^$/d;s/[[:blank:]]//g' | sed ':a;N;$!ba;s/\n//g' | sed 's/,$//') #remove whitespaces, linebreaks, and trailing comma
              status2=$(echo "$status" | sed 's/,/ /g' | sed 's/"//g') #replace internal commas with spaces and remove quotes
              status3=($(echo "$status2"))    #create an array with the values

              network=$(echo "${status3[1]}" | sed 's/.*://')

              txhash=$(echo "${status3[2]}" | sed 's/.*://')
              txhash2=$(echo "${status3[3]}" | sed 's/.*://')
              txhash=$(echo $txhash $txhash2)

              version=$(echo "${status3[7]}" | sed 's/.*://')

              lastseen=$(echo "${status3[8]}" | sed 's/.*://')

              if [[ $lastseen == "0" ]]; then
                lastseen_formatted="0"

              else
                lastseen_formatted=$(TZ=":US/Eastern" date -d @$lastseen +'%a %m-%d-%Y %I:%M:%S%P EST')

              fi

              activetime=$(echo "${status3[9]}" | sed 's/.*://')
              if [[ $activetime == "0" ]]; then
                activetime_formatted="0"

              else
      	        activetime_formatted=$(TZ=":US/Eastern" date -d @$activetime +'%Hhrs %Mms %Ssecs')
              fi

              lastpaid=$(echo "${status3[10]}" | sed 's/.*://')
              if [[ $lastpaid == "0" ]]; then
                lastpaid_formatted="0"

              else
                lastpaid_formatted=$(TZ=":US/Eastern" date -d @$lastpaid +'%a %m-%d-%Y %I:%M:%S%P EST')

              fi

              curl -X POST -H 'Content-type: application/json' --data '{ "text": "Alert: '"$tempLabel"' '"$i"' not ENABLED", "blocks": [ { "type": "header", "text": { "type": "plain_text", "text": "--------------------------------------------------------------\n--------------------------------------------------------------", "emoji": true} }, { "type": "section", "text": { "type": "mrkdwn", "text": ":mag::exclamation: *ALERT!* *STATUS:* '"$tempStatus"' :exclamation::mag_right:\n'"$tempLabel"' on server '"$server"' is not ENABLED " } }, { "type": "section", "text": { "type": "mrkdwn", "text": "<!date^'"$d"'^Posted {date_num} {time_secs}|'"$d_formatted"'>" } }, { "type": "divider" }, { "type": "section", "text": { "type": "mrkdwn", "text": "'"$tempLabel"' <https://guapexplorer.com/#/address/'"$i"'|'"$i"'> \n\n" } }, { "type": "divider" }, { "type": "section", "block_id": "section567", "text": { "type": "mrkdwn", "text": "*Attention Needed:* Please take a closer look at '"$tempLabel"'. \n\n Current data reported for '"$tempLabel"': \nstatus='"$tempStatus"' \nnetwork='"$network"' \ntxid='"$txhash"' \nversion='"$version"' \nlastseen='"$lastseen_formatted"' \nactivetime='"$activetime_formatted"' \nlastpaid='"$lastpaid_formatted"'\n\n" } }, { "type": "context", "elements": [ { "type": "mrkdwn", "text": "*Note:* Alert automatically generated by masternode monitoring system.\nPlease message <@U013QSJTGEA> for more information.\n\n" } ] }, {"type": "divider" }, {"type": "divider" } ] }'

      fi


  fi



  ((++n))
done

#echo "Masternode Statuses saved to $StatusReportFilename"

#Turn off environment variables
set +a