#!/bin/bash

#VERSION 4.0 of the Check and Save Guap Holdings script
#This script exclusively uses the API calls from https://guapexplorer.com

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

SnapshotFilename="/home/guapadmin/GUAP-Snapshot-$d_filename.txt"


echo "" | tee $SnapshotFilename
#Note: the tee command writes the onscreen report to a file also
echo "                   [GUAP Holdings Snaphot]                       " | tee -a $SnapshotFilename
echo "-----------------------------------------------------------------" | tee -a $SnapshotFilename

echo "Timestamp : $d_formatted" | tee -a $SnapshotFilename
echo "" | tee -a $SnapshotFilename
#echo "Test d: $d"

#Create arrays to hold GUAP addresses and address labels from file
declare -a MNArray
declare -a MNLabelArray

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

echo "" | tee -a $SnapshotFilename


echo "[Label]      [Address]                                [Subtotal] " | tee -a $SnapshotFilename
echo "-----------------------------------------------------------------" | tee -a $SnapshotFilename

echo "" | tee -a $SnapshotFilename

#For loop to get the current amount of GUAP in each saved GUAP address and print out each address, with its label and its GUAP amount
n=0
for i in "${MNArray[@]}"
do

  #parm="http://159.65.221.180:3001/ext/getbalance/$i"
  #Addr[$n]=$(curl -s -X GET $parm)
  Addr[$n]=$(curl -s https://guapexplorer.com/api/address/$i | awk -F, '{print $3}' | sed 's/.*://')

  tempVar=${Addr[$n]}
  tempLabel=${MNLabelArray[$n]}
  echo "  $tempLabel        $i : $(python -c 'import os; print "{0:>14,.3f}".format(float(os.environ["tempVar"]))')" | tee -a $SnapshotFilename
  echo "" | tee -a $SnapshotFilename

  ((++n))
done

#Var to hold the total amount of GUAP from all saved GUAP addresses, and For loop to iterate through MNArray and calculate the total of all the addresses
MN_Total=0
n=0
#Add everything up
for i in "${Addr[@]}"
do
  tempVar=${Addr[$n]}

  MN_Total=$(python -c 'import os; print "{:>14.3f}".format((float(os.environ["MN_Total"]) + float(os.environ["tempVar"])))')

  ((++n))
done

#Get total current GUAP chain money supply
#parm7="http://159.65.221.180:3001/ext/getmoneysupply"
parm7=$(curl -s https://guapexplorer.com/api/coin/ | awk -F, '{print $12}' | sed 's/.*://')

#GUAPTotal=$(curl -s -X GET $parm7)
GUAPTotal=$parm7

#Get percentage of total GUAP money suppy held by the addressed evaluated
Perc=$(python -c 'import os; print "{:>13,.2f}".format((float(os.environ["MN_Total"]) / float(os.environ["GUAPTotal"]) * 100))')

#Print out total holding and total GUAP money supply
echo "-----------------------------------------------------------------" | tee -a $SnapshotFilename
echo "  Total Current GUAP Holdings                   : $(python -c 'import os; print "{0:>14,.2f}".format(float(os.environ["MN_Total"]))')" | tee -a $SnapshotFilename

#Get current per GUAP value is USD
parm10=$(curl -s https://guapexplorer.com/api/coin/ | awk -F, '{print $13}' | sed 's/.*://')
GUAPValue=$parm10

GuapUSD=$(echo $MN_Total*$GUAPValue | bc)
GuapUSD=$(printf "%.2f\n" $GuapUSD) #Reformat to 2 decimal points
GuapUSDoffset=$(printf "\$%'13.2f\n" $GuapUSD) #Reformat to right justified for presentation purposes

echo "  Total Current GUAP Holdings (USD)             : $GuapUSDoffset" | tee -a $SnapshotFilename

echo "-----------------------------------------------------------------" | tee -a $SnapshotFilename

#Save MN_Total and timestamp to file output.text
echo "$d $MN_Total" > /home/guapadmin/output.text
#echo "" | tee -a $SnapshotFilename
echo "-----------------------------------------------------------------" | tee -a $SnapshotFilename
GUAPearned=$(echo $MN_Total-$LastGuapTotal | bc)
#echo "Test GUAPearned= $MN_Total-$LastGuapTotal"
#GUAPearned=$(python -c 'import os; print "{0:.0f}".format((float(os.environ["MN_Total"]) - float(os.environ["LastGuapTotal"])))')
#echo "Test GUAPearned= $GUAPearned"

GUAPearnedUSD=$(echo $GUAPearned*$GUAPValue | bc)
#echo "Test GUAPearnedUSD= $GUAPearnedUSD"
GUAPearnedUSD=$(printf "%'.2f\n" $GUAPearnedUSD)
#echo "Test GUAPearnedUSD 2nd format= $GUAPearnedUSD"
#For use in the per hour, minute, sec calculations below
GUAPearnedNoComma=$(python -c 'import os; print "{0:.0f}".format((float(os.environ["MN_Total"]) - float(os.environ["LastGuapTotal"])))')

d_var=$(TZ=":US/Eastern" date -d @$d +'%Y-%m-%dT%H:%M:%S')
LastGuapTime_var=$(TZ=":US/Eastern" date -d @$LastGuapTime +'%Y-%m-%dT%H:%M:%S')
#echo "d= $d_var"
#echo "LastGuapTime= $LastGuapTime_var"

TimeElapsed=$(dateutils.ddiff $d_var $LastGuapTime_var -f '%dd:%Hh:%Mm:%Ss')
#echo "Time elasped is $TimeElapsed"
#TimeElapsed_s=$(date -d  @$TimeElapsed +'%S')
#echo "  GUAP earned since last check @ $(date -d  @$LastGuapTime +'%m/%d %I:%M%P')  : $GUAPearned in last $(date -d  @$TimeElapsed +'%M%S') min"
echo "  Last check @ $(TZ=":US/Eastern" date -d  @$LastGuapTime +'%m/%d %I:%M:%S%P') EST" | tee -a $SnapshotFilename

#Remove thousands comma from GUAPearned variable
#GUAPearned=$(python -c 'import os; print "{0:.0f}".format(float(os.environ["GUAPearned"]))')

  echo "  Earned since  : $GUAPearned GUAP[\$$GUAPearnedUSD] in last $TimeElapsed" | tee -a $SnapshotFilename

TimeElapsedSec=$(dateutils.ddiff $d_var $LastGuapTime_var -f '%S')
TimeElapsedMin=$(dateutils.ddiff $d_var $LastGuapTime_var -f '%M')
TimeElapsedHr=$(dateutils.ddiff $d_var $LastGuapTime_var -f '%H')

if [[ $TimeElapsedHr > '0' ]]; then
  #echo "TimeElapsedHr = $TimeElapsedHr"
  #echo "TimeElapsedHr >0"
  GUAPearnRateH=$(python -c 'import os; print "{0:.2f}".format(abs((float(os.environ["GUAPearnedNoComma"]) / (float(os.environ["TimeElapsedSec"])/3600))))')
  GUAPUSDearnRateH=$(python -c 'import os; print "{0:,.2f}".format((float(os.environ["GUAPearnRateH"]) * float(os.environ["GUAPValue"])))')
  echo "  Earn rate/hr  : $GUAPearnRateH GUAP[\$$GUAPUSDearnRateH]/hour" | tee -a $SnapshotFilename
fi

if [[ $TimeElapsedMin > '0' ]]; then
  #echo "TimeElapsedMin = $TimeElapsedMin"
  #echo "TimeElapsedMin > 0"
  GUAPearnRateM=$(python -c 'import os; print "{0:.2f}".format(abs((float(os.environ["GUAPearnedNoComma"]) / (float(os.environ["TimeElapsedSec"])/60))))')
  GUAPUSDearnRateM=$(python -c 'import os; print "{0:,.2f}".format((float(os.environ["GUAPearnRateM"]) * float(os.environ["GUAPValue"])))')
  echo "  Earn rate/min : $GUAPearnRateM GUAP[\$$GUAPUSDearnRateM]/minute" | tee -a $SnapshotFilename
fi


#TimeElapsedMin=$(python -c 'import os; print "{:10.8f}".format(abs((float(os.environ["GUAPearned"]) / 60)))')
#TimeElapsedHr=$(python -c 'import os; print "{:10.8f}".format(abs((float(os.environ["GUAPearned"]) / 3600)))')

#echo "TimeElapsedSec=$TimeElapsedSec"


#  GUAPearnRateH=$(python -c 'import os; print "{:10.8f}".format(abs((float(os.environ["GUAPearned"]) / float(os.environ["TimeElapsedHr"]))))')
#  GUAPearnRateM=$(python -c 'import os; print "{:10.8f}".format(abs((float(os.environ["GUAPearned"]) / float(os.environ["TimeElapsedMin"]))))')
  GUAPearnRateS=$(python -c 'import os; print "{0:.2f}".format(abs((float(os.environ["GUAPearnedNoComma"]) / float(os.environ["TimeElapsedSec"]))))')
  GUAPUSDearnRateS=$(python -c 'import os; print "{0:,.2f}".format((float(os.environ["GUAPearnRateS"]) * float(os.environ["GUAPValue"])))')
#  echo "  Earn rate        :  [$GUAPearnRateH GUAP/hour   ]"
#  echo "                   :  [$GUAPearnRateM GUAP/minute ]"
#  echo "                   :  [$GUAPearnRateS GUAP/second ]"
echo "  Earn rate/sec : $GUAPearnRateS GUAP[\$$GUAPUSDearnRateS]/second" | tee -a $SnapshotFilename


echo "-----------------------------------------------------------------" | tee -a $SnapshotFilename
echo "" | tee -a $SnapshotFilename
echo "Total GUAP Money Supply                        :  $(python -c 'import os; print "{0:>14,.3f}".format(float(os.environ["GUAPTotal"]))')" | tee -a $SnapshotFilename
echo "" | tee -a $SnapshotFilename

GuapTotalUSD=$(echo $GUAPTotal*$GUAPValue | bc)
GuapTotalUSDoffset=$(printf "\$% '14,.3f\n" $GuapTotalUSD)
echo "Total GUAP Money Supply (USD)                  : $GuapTotalUSDoffset" | tee -a $SnapshotFilename
#echo "Total GUAP Money Supply (USD)                  :  $(python -c 'import os; print "{0:>14}".format("${:,.3f}".format(float(os.environ["GUAPTotal"]) * float(os.environ["GUAPValue"])))')" | tee -a $SnapshotFilename

echo "" | tee -a $SnapshotFilename

#Get total number of GUAP masternodes and do some formating
#parm8="http://159.65.221.180:3001/ext/getmasternodecount"
parm8=$(curl -s https://guapexplorer.com/api/coin/ | awk -F, '{print $8}' | sed 's/.*://')
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
#BlockHeight=$(curl -s -X GET $parm9)
BlockHeight=$parm9
BlockHeight=$(printf '%14s' $BlockHeight) #Reformat to right justify

echo "Current per GUAP Value (USD)                   :  $(python -c 'import os; print "{0:>14}".format("${:,.4f}".format( float(os.environ["GUAPValue"]) ) )')" | tee -a $SnapshotFilename



echo "" | tee -a $SnapshotFilename

#Print out percentage of GUAP money supply, Masternode count, and GUAP chain block count/height
echo "Percentage of total GUAP Money Supply          :  $Perc%" | tee -a $SnapshotFilename
echo "" | tee -a $SnapshotFilename

echo "Total number of GUAP masternodes               :  $MNCount" | tee -a $SnapshotFilename
MNCount=$(python -c 'import os; print "{0:>14,.0f}".format(float(os.environ["MNCount"]))')
n=$(python -c 'import os; print "{0:>14,.0f}".format(float(os.environ["n"]))')
echo "" | tee -a $SnapshotFilename

#Get percentage of total GUAP voting power
#decrease n variable because of the 2 change addresses we are tracking
#n=$((n-2))
Perc2=$(python -c 'import os; print "{:>13,.2f}".format((float(os.environ["n"]) / float(os.environ["MNCount"]) * 100))')

echo "Percentage of total GUAP Voting Power          :  $Perc2%" | tee -a $SnapshotFilename
echo "" | tee -a $SnapshotFilename
echo "GUAP Chain Block Count                         :  $BlockHeight" | tee -a $SnapshotFilename
echo "" | tee -a $SnapshotFilename

#Save MN_Total and timestamp to the snapshot
echo "$d $MN_Total" >> tee -a $SnapshotFilename
echo "GUAP Snapshot saved to $SnapshotFilename"

#Turn off environment variables
set +a
