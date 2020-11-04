#!/bin/bash

#VERSION 5.0 of the Check and Save Guap Holdings script
#This script uses the API calls from https://guapexplorer.com, from https://probit.com and direct calls from the Guapcoin Blockchain
#This script assumes that the default wallet via guapcoin-cli calls is fully synced

#This script should be called with text input file (e.g. file.txt) and an output file (e.g. output.text) as an argument:
# e.g sudo /home/guapadmin/ChkGuapHoldingsv3.sh /home/guapadmin/file.text /home/guapadmin/ouput.text

#The input text file should have the GUAP addresses you want to check the amounts for and a corresponding label for each address
#Format for the text should be:
#     Label1<space>GUAP Address1
#     Label2<space>GUAP Address2

#The output text file has no formatting requirements.



#Make all variable available as environment variables
set -a

#Print timestamp in Day Date(MM-DD-YYYY) Time(HH:MMam) Timezone format
#d_epoch=$(TZ=":US/Eastern" date +"%s")
d=$(TZ=":US/Eastern" date +"%s")
d_formatted=$(TZ=":US/Eastern" date -d @$d +'%a %m-%d-%Y %I:%M:%S%P EST')
d_filename=$(TZ=":US/Eastern" date -d @$d +'%a_%m-%d-%Y_%I:%M:%S%P_EST')
server=$(hostname)
MNs_data1A=""
MNs_data1B=""
MNs_data2A=""
MNs_data2B=""
MNs_data3A=""
MNs_data3B=""
MNs_data4A=""
MNs_data4B=""
MNs_data5A=""
MNs_data5B=""
MNs_data6A=""
MNs_data6B=""
MNs_Data_Block=""
MNs_Data_Block1=""
MNs_Data_Block2=""
MNs_Data_Block3=""
MNs_Data_Block4=""
MNs_Data_Block5=""
MNs_Data_Block6=""
SnapshotFilename="/home/guapadmin/MN_Report/GUAP-Snapshot-$d_filename.txt"


echo "" >> $SnapshotFilename
#Note: the tee command writes the onscreen report to a file also
echo "               [GUAP Holdings Snaphot Rev 5.0]                   " >> $SnapshotFilename
echo "-----------------------------------------------------------------" >> $SnapshotFilename

echo "Timestamp : $d_formatted" >> $SnapshotFilename
echo "" >> $SnapshotFilename
#echo "Test d: $d"

#Create arrays to hold GUAP addresses and address labels from file, and Guap totals from API calls
declare -a MNArray
declare -a MNLabelArray
declare -a Addr
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

#Read in last GUAPtotal and timestamp from output.text
LastGuapFile="/home/guapadmin/output.text"
if test -f "$LastGuapFile"; then
  while read -r time total; do
    LastGuapTime=$time
    LastGuapTotal=$total
  done < $LastGuapFile
fi

echo "" >> $SnapshotFilename


echo "[Label]      [Address]                                [Subtotal] " >> $SnapshotFilename
echo "-----------------------------------------------------------------" >> $SnapshotFilename

echo "" >> $SnapshotFilename

#For loop to get the current amount of GUAP in each saved GUAP address and print out each address, with its label and its GUAP amount
n=0

for i in "${MNArray[@]}"
do
  temp_MNs_dataA=""
  temp_MNs_dataB=""
  #parm="http://159.65.221.180:3001/ext/getbalance/$i"
  #Addr[$n]=$(curl -s -X GET $parm)
  Addr[$n]=$(curl -s https://guapexplorer.com/api/address/$i | awk -F, '{print $3}' | sed 's/.*://')

  tempVar=${Addr[$n]}
  tempLabel=${MNLabelArray[$n]}
  echo "  $tempLabel        $i : $(python -c 'import os; print "{0:>14,.3f}".format(float(os.environ["tempVar"]))')" >> $SnapshotFilename
  echo "" >> $SnapshotFilename

  if [[ $tempLabel == *M* ]]; then #Skip addresses that are not labeled as masternodes
    temp_MNs_dataA="<https://guapexplorer.com/#/address/$i| Masternode $tempLabel>\n "
  else
    temp_MNs_dataA="<https://guapexplorer.com/#/address/$i| GUAP ID $tempLabel>\n "
  fi

  temp_MNs_dataB="$(python -c 'import os; print "{0:,.2f}".format(float(os.environ["tempVar"]))')\n"
  #curl command to send data to slack can only handle about 10 entries per field block, so it is broken up here (max 60 entries)
  if [ "$n" -lt 10 ];then
    MNs_data1A="$MNs_data1A$temp_MNs_dataA"
    MNs_data1B="$MNs_data1B$temp_MNs_dataB"
    MNs_Data_Block1="{ \"type\": \"section\", \"fields\": [ { \"type\": \"mrkdwn\", \"text\": \"*ID*\" }, { \"type\": \"mrkdwn\", \"text\": \"*Subtotal*\" }, { \"type\": \"mrkdwn\", \"text\": \"$MNs_data1A\" }, { \"type\": \"mrkdwn\", \"text\": \"$MNs_data1B\" } ] }"
    MNs_Data_Block=$MNs_Data_Block1
  elif [[ "$n" -gt 9 ]] && [[ "$n" -lt 20 ]]; then
    MNs_data2A="$MNs_data2A$temp_MNs_dataA"
    MNs_data2B="$MNs_data2B$temp_MNs_dataB"
    MNs_Data_Block2="$MNs_Data_Block1, { \"type\": \"section\", \"fields\": [ { \"type\": \"mrkdwn\", \"text\": \"*ID*\" }, { \"type\": \"mrkdwn\", \"text\": \"*Subtotal*\" }, { \"type\": \"mrkdwn\", \"text\": \"$MNs_data2A\" }, { \"type\": \"mrkdwn\", \"text\": \"$MNs_data2B\" } ] }"
    MNs_Data_Block=$MNs_Data_Block2
  elif [[ "$n" -gt 19 ]] && [[ "$n" -lt 30 ]]; then
    MNs_data3A="$MNs_data3A$temp_MNs_dataA"
    MNs_data3B="$MNs_data3B$temp_MNs_dataB"
    MNs_Data_Block3="$MNs_Data_Block2, { \"type\": \"section\", \"fields\": [ { \"type\": \"mrkdwn\", \"text\": \"*ID*\" }, { \"type\": \"mrkdwn\", \"text\": \"*Subtotal*\" }, { \"type\": \"mrkdwn\", \"text\": \"$MNs_data3A\" }, { \"type\": \"mrkdwn\", \"text\": \"$MNs_data3B\" } ] }"
    MNs_Data_Block=$MNs_Data_Block3
  elif [[ "$n" -gt 29 ]] && [[ "$n" -lt 40 ]]; then
    MNs_data4A="$MNs_data4A$temp_MNs_dataA"
    MNs_data4B="$MNs_data4B$temp_MNs_dataB"
    MNs_Data_Block4="$MNs_Data_Block3, { \"type\": \"section\", \"fields\": [ { \"type\": \"mrkdwn\", \"text\": \"*ID*\" }, { \"type\": \"mrkdwn\", \"text\": \"*Subtotal*\" }, { \"type\": \"mrkdwn\", \"text\": \"$MNs_data4A\" }, { \"type\": \"mrkdwn\", \"text\": \"$MNs_data4B\" } ] }"
    MNs_Data_Block=$MNs_Data_Block4
  elif [[ "$n" -gt 39 ]] && [[ "$n" -lt 50 ]]; then
    MNs_data5A="$MNs_data5A$temp_MNs_dataA"
    MNs_data5B="$MNs_data5B$temp_MNs_dataB"
    MNs_Data_Block5="$MNs_Data_Block4, { \"type\": \"section\", \"fields\": [ { \"type\": \"mrkdwn\", \"text\": \"*ID*\" }, { \"type\": \"mrkdwn\", \"text\": \"*Subtotal*\" }, { \"type\": \"mrkdwn\", \"text\": \"$MNs_data5A\" }, { \"type\": \"mrkdwn\", \"text\": \"$MNs_data5B\" } ] }"
    MNs_Data_Block=$MNs_Data_Block5
  elif [[ "$n" -gt 49 ]] && [[ "$n" -lt 60 ]]; then
    MNs_data6A="$MNs_data6A$temp_MNs_dataA"
    MNs_data6B="$MNs_data6B$temp_MNs_dataB"
    MNs_Data_Block6="$MNs_Data_Block5, { \"type\": \"section\", \"fields\": [ { \"type\": \"mrkdwn\", \"text\": \"*ID*\" }, { \"type\": \"mrkdwn\", \"text\": \"*Subtotal*\" }, { \"type\": \"mrkdwn\", \"text\": \"$MNs_data6A\" }, { \"type\": \"mrkdwn\", \"text\": \"$MNs_data6B\" } ] }"
    MNs_Data_Block=$MNs_Data_Block6
  fi

  ((++n))
done

#MNs_data=$(echo "$MNs_data" | sed "s/\'//g")
#Var to hold the total amount of GUAP from all saved GUAP addresses, and For loop to iterate through MNArray and calculate the total of all the addresses
MN_Total=0
n=0
#Add everything up
for i in "${Addr[@]}"
do
  tempVar1=$MN_Total
  tempVar2=${Addr[$n]}
  MN_Total=$(echo $tempVar1+$tempVar2 | bc)
  #MN_Total=$(python -c 'import os; print "{:>14.3f}".format((float(os.environ["MN_Total"]) + float(os.environ["tempVar"])))' >/dev/null 2>&1)

  ((++n))
done

#Get total current GUAP chain money supply
#parm7="http://159.65.221.180:3001/ext/getmoneysupply"
parm7=$(curl -s https://guapexplorer.com/api/coin/ | awk -F, '{print $12}' | sed 's/.*://')
#parm7=$(guapcoin-cli getinfo | awk '/moneysupply/' | sed 's/.*://' | sed 's/,$//')
#GUAPTotal=$(curl -s -X GET $parm7)
GUAPTotal=$parm7

#Get percentage of total GUAP money suppy held by the addressed evaluated
Perc=$(echo "scale=4;$MN_Total/$GUAPTotal" | bc -l)
Perc=$(echo $Perc*100 | bc)
#Perc=$(python -c 'import os; print "{:>13,.2f}".format((float(os.environ["MN_Total"]) / float(os.environ["GUAPTotal"]) * 100))' >/dev/null 2>&1)

#Print out total holding and total GUAP money supply
echo "-----------------------------------------------------------------" >> $SnapshotFilename
echo "  Total Current GUAP Holdings                   : $(python -c 'import os; print "{0:>14,.2f}".format(float(os.environ["MN_Total"]))' >/dev/null 2>&1)" >> $SnapshotFilename

#Get current per GUAP value in USD (currently must be pulled from probit.com APIs)
#Value of GUAP in BTC
parm10a=$(curl -s https://api.probit.com/api/exchange/v1/ticker?market_ids=GUAP-BTC | awk -F, '{print $1}' | sed 's/.*://' | sed 's/"//g')

#Value of BTC in USDT
parm10b=$(curl -s https://api.probit.com/api/exchange/v1/ticker?market_ids=BTC-USDT | awk -F, '{print $1}' | sed 's/.*://' | sed 's/"//g')

#parm10=$(curl -s https://guapexplorer.com/api/coin/ | awk -F, '{print $13}' | sed 's/.*://')
#Calculate GUAP USD value
parm10=$(echo $parm10a*$parm10b | bc)

GUAPValue=$parm10

GuapUSD=$(echo $MN_Total*$GUAPValue | bc)
GuapUSD1=$(printf "%.2f\n" $GuapUSD) #Reformat to 2 decimal points
GuapUSDoffset=$(printf "\$%'13.2f\n" $GuapUSD1) #Reformat to right justified for presentation purposes

echo "  Total Current GUAP Holdings (USD)             : $GuapUSDoffset" >> $SnapshotFilename

echo "-----------------------------------------------------------------" >> $SnapshotFilename

#Save MN_Total and timestamp to file output.text
echo "$d $MN_Total" > /home/guapadmin/output.text
echo "-----------------------------------------------------------------" >> $SnapshotFilename
GUAPearned=$(echo "$MN_Total-$LastGuapTotal" | bc)
GUAPearned=$(printf "%.3f\n" $GUAPearned)
#echo "Test GUAPearned= $MN_Total-$LastGuapTotal"
#GUAPearned=$(python -c 'import os; print "{0:.0f}".format((float(os.environ["MN_Total"]) - float(os.environ["LastGuapTotal"])))')

GUAPearnedUSD=$(echo $GUAPearned*$GUAPValue | bc)

GUAPearnedUSD=$(printf "%'.2f\n" $GUAPearnedUSD)

GUAPearnedUSD1="\$$GUAPearnedUSD"


#For use in the per hour, minute, sec calculations below
GUAPearnedNoComma=$GUAPearned
#GUAPearnedNoComma=$(python -c 'import os; print "{0:.0f}".format((float(os.environ["MN_Total"]) - float(os.environ["LastGuapTotal"])))' >/dev/null 2>&1)

d_var=$(TZ=":US/Eastern" date -d @$d +'%Y-%m-%dT%H:%M:%S')
LastGuapTime_var=$(TZ=":US/Eastern" date -d @$LastGuapTime +'%Y-%m-%dT%H:%M:%S')

TimeElapsed=$(dateutils.ddiff $d_var $LastGuapTime_var -f '%dd:%Hh:%Mm:%Ss')

echo "  Last check @ $(TZ=":US/Eastern" date -d  @$LastGuapTime +'%m/%d %I:%M:%S%P') EST" >> $SnapshotFilename



echo "  Earned since  : $GUAPearned GUAP[\$$GUAPearnedUSD] in last $TimeElapsed" >> $SnapshotFilename

TimeElapsedSec=$(dateutils.ddiff $d_var $LastGuapTime_var -f '%S')
TimeElapsedMin=$(dateutils.ddiff $d_var $LastGuapTime_var -f '%M')
TimeElapsedHr=$(dateutils.ddiff $d_var $LastGuapTime_var -f '%H')
TimeElapsedSec=$(echo "$TimeElapsedSec" | sed 's/-//g')

GUAPearnRateH=""
GUAPUSDearnRateH=""
EarnRateVar="Earn rate:                    "
EarnRateVarUSD="Earn rate(USD):          "
if [[ $TimeElapsedHr > '0' ]]; then
  #echo "TimeElapsedHr = $TimeElapsedHr"
  #echo "TimeElapsedHr >0"
  tempRate=3600
  GUAPearnRateH=$(echo "scale=2;$GUAPearned/$TimeElapsedSec*$tempRate" | bc -l)
  GUAPUSDearnRateH=$(echo "scale=2;$GUAPearnRateH*$GUAPValue" | bc -l)
  GUAPUSDearnRateH1=$(printf "%.2f\n" $GUAPUSDearnRateH)
  #GUAPearnRateH=$(python -c 'import os; print "{0:.2f}".format(abs((float(os.environ["GUAPearnedNoComma"]) / (float(os.environ["TimeElapsedSec"])/3600))))' >/dev/null 2>&1)
  #GUAPUSDearnRateH=$(python -c 'import os; print "{0:,.2f}".format((float(os.environ["GUAPearnRateH"]) * float(os.environ["GUAPValue"])))' >/dev/null 2>&1)

  echo "  Earn rate/hr  : $GUAPearnRateH GUAP[\$$GUAPUSDearnRateH]/hour" >> $SnapshotFilename
  EarnRateVar="$EarnRateVar  $GUAPearnRateH GUAP/hour"
  EarnRateVarUSD="$EarnRateVarUSD  \$$GUAPUSDearnRateH1/hour"
fi

GUAPearnRateM=""
GUAPUSDearnRateM=""
if [[ $TimeElapsedMin > '0' ]]; then
  #echo "TimeElapsedMin = $TimeElapsedMin"
  #echo "TimeElapsedMin > 0"
  tempRate=60
  GUAPearnRateM=$(echo "scale=2;$GUAPearned/$TimeElapsedSec*$tempRate" | bc -l)
  GUAPUSDearnRateM=$(echo "scale=2;$GUAPearnRateM*$GUAPValue" | bc -l)
  GUAPUSDearnRateM1=$(printf "%.2f\n" $GUAPUSDearnRateM)
  #GUAPearnRateM=$(python -c 'import os; print "{0:.3f}".format(abs((float(os.environ["GUAPearnedNoComma"]) / (float(os.environ["TimeElapsedSec"])/60))))' >/dev/null 2>&1)
  #GUAPUSDearnRateM=$(python -c 'import os; print "{0:,.3f}".format((float(os.environ["GUAPearnRateM"]) * float(os.environ["GUAPValue"])))' >/dev/null 2>&1)

  echo "  Earn rate/min : $GUAPearnRateM GUAP[\$$GUAPUSDearnRateM]/minute" >> $SnapshotFilename
  EarnRateVar="$EarnRateVar  $GUAPearnRateM GUAP/min"
  EarnRateVarUSD="$EarnRateVarUSD  \$$GUAPUSDearnRateM1/min"
fi

GUAPearnRateS=$(echo "scale=2;$GUAPearned/$TimeElapsedSec" | bc -l)
GUAPUSDearnRateS=$(echo "scale=2;$GUAPearnRateS*$GUAPValue" | bc -l)
GUAPUSDearnRateS1=$(printf "%.2f\n" $GUAPUSDearnRateS)
#GUAPearnRateS=$(python -c 'import os; print "{0:.4f}".format(abs((float(os.environ["GUAPearnedNoComma"]) / float(os.environ["TimeElapsedSec"]))))' >/dev/null 2>&1)
#GUAPUSDearnRateS=$(python -c 'import os; print "{0:,.4f}".format((float(os.environ["GUAPearnRateS"]) * float(os.environ["GUAPValue"])))' >/dev/null 2>&1)

echo "  Earn rate/sec : $GUAPearnRateS GUAP[\$$GUAPUSDearnRateS]/second" >> $SnapshotFilename
EarnRateVar="$EarnRateVar  $GUAPearnRateS GUAP/sec"
EarnRateVarUSD="$EarnRateVarUSD  \$$GUAPUSDearnRateS1/sec"

echo "-----------------------------------------------------------------" >> $SnapshotFilename
echo "" >> $SnapshotFilename
echo "Total GUAP Money Supply                        :  $(python -c 'import os; print "{0:>14,.3f}".format(float(os.environ["GUAPTotal"]))' >/dev/null 2>&1)" >> $SnapshotFilename
echo "" >> $SnapshotFilename

GuapTotalUSD=$(echo $GUAPTotal*$GUAPValue | bc)
GuapTotalUSDoffset=$(printf "\$% '14.3f\n" $GuapTotalUSD)
echo "Total GUAP Money Supply (USD)                  : $GuapTotalUSDoffset" >> $SnapshotFilename
#echo "Total GUAP Money Supply (USD)                  :  $(python -c 'import os; print "{0:>14}".format("${:,.3f}".format(float(os.environ["GUAPTotal"]) * float(os.environ["GUAPValue"])))')" >> $SnapshotFilename

echo "" >> $SnapshotFilename
echo "" >> $SnapshotFilename
#echo "$d $MN_Total" >> $SnapshotFilename
#Get total number of GUAP masternodes and do some formating
#parm8="http://159.65.221.180:3001/ext/getmasternodecount"
parm8=$(curl -s https://guapexplorer.com/api/coin/ | awk -F, '{print $8}' | sed 's/.*://')
#parm8=$(guapcoin-cli getmasternodecount | awk '/stable/' | sed 's/.*://' | sed 's/,$//')
#MNCount=$(curl -s -X GET $parm8)
MNCount=$parm8

#Removes random whitespace from beginning of MNCount
shopt -s extglob
MNCount=${MNCount##*( )}
shopt -u extglob
#right justify
MNCount=$(printf '%14s' $MNCount)




#Get current block count/height
#parm9="http://159.65.221.180:3001/api/getblockcount"
parm9=$(curl -s https://guapexplorer.com/api/coin/ | awk -F, '{print $4}' | sed 's/.*://')
#parm9=$(guapcoin-cli getblockcount)
#BlockHeight=$(curl -s -X GET $parm9)
BlockHeight=$parm9
BlockHeight=$(printf '%14s' $BlockHeight) #Reformat to right justify

echo "Current per GUAP Value (USD)                   :  $(python -c 'import os; print "{0:>14}".format("${:,.4f}".format( float(os.environ["GUAPValue"]) ) )' >/dev/null 2>&1)" >> $SnapshotFilename



echo "" >> $SnapshotFilename

#Print out percentage of GUAP money supply, Masternode count, and GUAP chain block count/height
echo "Percentage of total GUAP Money Supply          :  $Perc%" >> $SnapshotFilename
echo "" >> $SnapshotFilename

echo "Total number of GUAP masternodes               :  $MNCount" >> $SnapshotFilename
#MNCount=$(python -c 'import os; print "{0:>14,.0f}".format(float(os.environ["MNCount"]))' >/dev/null 2>&1)
#n=$(python -c 'import os; print "{0:>14,.0f}".format(float(os.environ["n"]))' >/dev/null 2>&1)
n=$(echo "$n-2" | bc)
echo "" >> $SnapshotFilename

#Get percentage of total GUAP voting power
#decrease n variable because of the 2 change addresses we are tracking
#n=$((n-2))


Perc2=$(echo "scale=4;$n/$parm8" | bc -l)
Perc2=$(echo $Perc2*100 | bc)
#Perc2=$(python -c 'import os; print "{:>13,.2f}".format((float(os.environ["n"]) / float(os.environ["MNCount"]) * 100))' >/dev/null 2>&1)
#Perc2b=$(python -c 'import os; print "{:>13,.2f}".format(float(os.environ["Perc2"]))' >/dev/null 2>&1)

echo "Percentage of total GUAP Voting Power          :  $Perc2%" >> $SnapshotFilename
echo "" >> $SnapshotFilename
echo "GUAP Chain Block Count                         :  $BlockHeight" >> $SnapshotFilename
echo "" >> $SnapshotFilename
echo "" >> $SnapshotFilename

#Save Previous timestamp and total to the snapshot
echo "$LastGuapTime $LastGuapTotal" >> $SnapshotFilename
echo "" >> $SnapshotFilename
#Save MN_Total and timestamp to the snapshot
echo "$d $MN_Total" >> $SnapshotFilename
#echo "GUAP Snapshot saved to $SnapshotFilename"

#echo "MNs_Data_Block= $MNs_Data_Block\n\n"
echo ""
curl -X POST -H 'Content-type: application/json' --data '{ "text": ":moneybag: GUAP MASTERNODE EARNINGS REPORT :moneybag:", "blocks": [ { "type": "header", "text": { "type": "plain_text", "text": "--------------------------------------------------------------\n--------------------------------------------------------------", "emoji": true} }, { "type": "section", "text": { "type": "mrkdwn", "text": ":dollar::moneybag: *GUAP MASTERNODE EARNINGS REPORT* :moneybag::dollar:\nMasternode Report for owner '"$server"'." } }, { "type": "context", "elements": [ { "type": "mrkdwn", "text": "Please see below a snapshot of your masternodes. See also included below links for your masternodes where you can view their recent transaction activity on the GUAP Blockchain Explorer. " } ] }, { "type": "section", "text": { "type": "mrkdwn", "text": "<!date^'"$d"'^Posted {date_num} {time_secs}|Posted '"$d_formatted"'>" } }, { "type": "divider" },  '"$MNs_Data_Block"', { "type": "divider" }, { "type": "section", "text": { "type": "mrkdwn", "text": "*GUAP Holdings*                                                                                       *'"$(python -c 'import os; print "{0:>14,.2f}".format(float(os.environ["MN_Total"]))')"'*\n*GUAP Holdings (USD)*                                                                          *'"$(python -c 'import os; print "{0:>14}".format("${:,.2f}".format(float(os.environ["GuapUSD"])))')"'* " } }, { "type": "divider" }, { "type": "section", "text": { "type": "mrkdwn", "text": "\nLast report was generated on '"$(TZ=":US/Eastern" date -d  @$LastGuapTime +'%m/%d %I:%M:%S%P')"' EST \nEarned since:                '"$GUAPearned"' GUAP ['"$GUAPearnedUSD1"'] in last '"$TimeElapsed"' \n'"$EarnRateVar"'   \n'"$EarnRateVarUSD"' "} }, { "type": "divider" }, { "type": "section", "text": { "type": "mrkdwn", "text": "*GUAP Stats* \nGUAP Money Supply                                                                                '"$(python -c 'import os; print "{0:>14,.2f}".format(float(os.environ["GUAPTotal"]))')"' \nGUAP Money Supply (USD)                                                                     '"$(python -c 'import os; print "{0:>14}".format("${:,.2f}".format(float(os.environ["GuapTotalUSD"])))')"' \nGUAP Value (USD)                                                                              '"$(python -c 'import os; print "{0:>14}".format("${:,.4f}".format(float(os.environ["GUAPValue"])))')"' \n% of GUAP Money Supply                                                                         '"$Perc"'% \nTotal GUAP masternodes                                                                         '"$parm8"' \n% of GUAP voting power                                                                         '"$Perc2"'% \nGUAP Chain Block Count                                                                  '"$BlockHeight"' " } }, { "type": "divider" }, { "type": "context", "elements": [ { "type": "mrkdwn", "text": "*Note:* Report automatically generated by masternode monitoring system. \nPlease message <@U013QSJTGEA> for further details or with questions/concerns." } ] }, { "type": "divider" }, { "type": "divider" } ] }'

#Turn off environment variables
set +a
