#!/bin/bash

#VERSION 1.0 of the Report MN Status script

#Make all variable available as environment variables
set -a

#Print timestamp in Day Date(MM-DD-YYYY) Time(HH:MMam) Timezone format
#d_epoch=$(TZ=":US/Eastern" date +"%s")
d=$(TZ=":US/Eastern" date +"%s")
d_formatted=$(TZ=":US/Eastern" date -d @$d +'%a %m-%d-%Y %I:%M:%S%P EST')
d_filename=$(TZ=":US/Eastern" date -d @$d +'%a_%m-%d-%Y_%I:%M:%S%P_EST')

StatusReportFilename="/home/guapadmin/MN-Status-Report-$d_filename.txt"


echo "" | tee $StatusReportFilename
#Note: the tee command writes the onscreen report to a file also
echo "               [Masternode Status Report Rev 1.0]                " | tee -a $StatusReportFilename
echo "-----------------------------------------------------------------" | tee -a $StatusReportFilename

echo "Timestamp : $d_formatted" | tee -a $StatusReportFilename
echo "" | tee -a $StatusReportFilename
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

echo "" | tee -a $StatusReportFilename


echo "[Label]      [Address]                                [Subtotal] " | tee -a $StatusReportFilename
echo "-----------------------------------------------------------------" | tee -a $StatusReportFilename

echo "" | tee -a $StatusReportFilename

#For loop to get the current status each saved GUAP address and print out each address, with its label and its GUAP amount. Also send an alert through slack for that MN if the status is not "ENABLED"
n=0
for i in "${MNArray[@]}"
do

  dir="/home/guapadmin/.guapcoin"

    if $(test -d $dir && echo true); then
        tempStatus=$(guapcoin-cli listmasternodes | grep -A1 \"status\" | grep -B1 "GajS6csTmrZtZLbN1APK7dwNPYqtUX9JjW" | sed '$d' | sed 's/,//g' | sed 's/\"status\"://g' | sed 's/"//g' | sed 's/^[[:space:]]*//g')
    else
        tempStatus=$(guapcoin-cli -conf=/home/guapadmin/.guapcoin1/guapcoin.conf -datadir=/home/guapadmin/.guapcoin1 listmasternodes | grep -A1 \"status\" | grep -B1 "GajS6csTmrZtZLbN1APK7dwNPYqtUX9JjW" | sed '$d' | sed 's/,//g' | sed 's/\"status\"://g' | sed 's/"//g' | sed 's/^[[:space:]]*//g')
    fi


  tempLabel=${MNLabelArray[$n]}
  echo "  $tempLabel        $i     Status: $tempStatus" | tee -a $StatusReportFilename
  echo "" | tee -a $StatusReportFilename

  if ! [["$tempStatus" == "ENABLED"]]; then
    Message="ALERT: On $tempLabel, $i, Status: $tempStatus"

    curl -X POST -H 'Content-type: application/json' --data '{"text":"'"$Message"'"}' https://hooks.slack.com/services/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

  fi

  ((++n))
done

echo "Masternode Statuses saved to $StatusReportFilename"

#Turn off environment variables
set +a
