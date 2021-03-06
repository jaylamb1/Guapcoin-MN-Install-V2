#!/bin/bash

# Make sure curl is installed
clear
echo "Preparing background tools..."
apt-get -qq update
clear
echo "Preparing background tools... ... "
apt -qqy install curl jq > /dev/null 2>&1
clear

# Make sure dig and systemctl are installed
echo "Preparing background tools... ... ..."
apt-get install git dnsutils systemd -y > /dev/null 2>&1
clear

# Make sure dig and systemctl are installed
echo "Preparing background tools... ... ... ..."

# CHARS is used for the loading animation further down.
CHARS="/-\|"
clear

MNID=""

echo "
 ___T_
| o o |
|__-__|
/| []|\\
()/|___|\()
|_|_|
/_|_\  ----------- MASTERNODE REFRESH v3 ----------------+
|                                                        |
|    This script will refresh the MN of your choice.     |
|    This script is compatible with V2 od GUAP only.     |
|                                                        |
| You must specify the ID# of the MN you wish to refresh |
|   E.g. If you want to refresh your initial MN, which   |
|        would have an ID# of '1', you enter '1',        |
|    but if you want to refresh your 3rd MN, which you   |
| have assigned a ID# of '3', you would enter '3' below. |
|                                                        |
|  If you used an a different naming convention than the |
|    sequential one described above, then follow that.   |
|                                                        |
| It's assumed that your MN(s) were installed under root |
|                                                        |::
+--------------------------------------------------------+::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::
"
sleep 3
echo ""
read -rp "Press Ctrl-C to abort or any other key to continue. " -n1 -s
clear

# Check if we are root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root." 1>&2
   exit 1
fi


while ! [ "$MNID" -eq "$MNID" ] 2> /dev/null
do
  echo "Enter the single digit Masternode ID# for the MN you want to refresh."
  echo "MNIDs for active masternodes detected on this VPS are:"
  MNarray[0]=0 #test for .guapcoin
  Starti=0
  FILE=/etc/systemd/system/guapcoin.service

  if test -f "$FILE"; then
      MNarray[0]=1
      echo "0"
      Starti=1
  fi

  for (( i = $Starti; i < 30; i++ )); do
      FILE=/etc/systemd/system/guapcoin$i.service
      if test -f "$FILE"; then
          MNarray[$i]=1
          echo "$i"
      fi
  done
  echo ""
  read -e -p "(Please choose an ID# from the above list of detected MNs) : " MNID

  # Make sure that $MNID is a number
  if ! [ "$MNID" -eq "$MNID" ] 2> /dev/null
  then
      echo ""
      echo "Sorry, the ID# must be a single digit integer corresponding to the MNID you want to refresh."
      echo ""
      read -rp "Press any key to continue. " -n1 -s
      clear
      continue
  fi

echo ""
echo "Your chosen MNID is: $MNID"
#echo test printing MNarray[\$MIND]: ${MNarray["$MNID"]}
  # Make sure that the masternode ID chosen corresponds to a MN installed on this VPS. Check for a corresponding guapcoin directory
if ! [ "${MNarray["$MNID"]}" == "1" ] 2> /dev/null
then
  #statements
  echo "Sorry, the ID# you've chosen does not correspond to a MNID detected on this VPS."
  echo ""
  read -rp "Press any key to continue and chose another. " -n1 -s
  echo ""
  echo ""
  MNID=""
  clear
  continue
fi

done

if [[ "$MNID" == "0" ]]; then
  #statements
  MNID=""
  #echo " test guapcoin$MNID"
fi

USER="guapadmin"
USERHOME=`eval echo "~$USER"`

echo "Stopping service for MNID #$MNID"
sleep 1

systemctl stop guapcoin$MNID.service
sleep 2
if systemctl status guapcoin$MNID | grep -q "inactive (dead)"; then
  echo "guapcoin$MNID.service stopped. Continue process..."
  sleep 2
else
  echo "ERROR: Failed to stop guapcoin$MNID.service. Please contact support. Exiting script."
  exit
fi

clear
echo "Refreshing node, please wait."

sleep 5

rm -rf /home/guapadmin/.guapcoin$MNID/sporks 2> /dev/null
rm -rf /home/guapadmin/.guapcoin$MNID/blocks 2> /dev/null
rm -rf /home/guapadmin/.guapcoin$MNID/database 2> /dev/null
rm -rf /home/guapadmin/.guapcoin$MNID/chainstate 2> /dev/null
rm -rf /home/guapadmin/.guapcoin$MNID/peers.dat 2> /dev/null
rm -rf /home/guapadmin/.guapcoin$MNID/db.log 2> /dev/null
rm -rf /home/guapadmin/.guapcoin$MNID/debug.log 2> /dev/null
rm -rf /home/guapadmin/.guapcoin$MNID/fee_estimates.dat 2> /dev/null
rm -rf /home/guapadmin/.guapcoin$MNID/mncache.dat 2> /dev/null
rm -rf /home/guapadmin/.guapcoin$MNID/mnpayments.dat 2> /dev/null
rm -rf /home/guapadmin/.guapcoin$MNID/banlist.dat 2> /dev/null
rm -rf /home/guapadmin/.guapcoin$MNID/budget.dat 2> /dev/null
rm -rf /home/guapadmin/.guapcoin$MNID/.lock 2> /dev/null
rm -rf /home/guapadmin/.guapcoin$MNID/wallet.dat 2> /dev/null
#Load bootstrap

#remove old bootstrap if it exists
rm -rf /home/guapadmin/.guapcoin$MNID/bootstrap.tar.gz 2> /dev/null

cd /home/guapadmin/.guapcoin$MNID/ && wget http://45.63.25.141/bootstrap.tar.gz
cd /home/guapadmin/.guapcoin$MNID/ && tar -xzvf bootstrap.tar.gz

rm -rf /home/guapadmin/.guapcoin$MNID/bootstrap.tar.gz

#backup the conf file just in case
cp $USERHOME/.guapcoin$MNID/guapcoin.conf $USERHOME/.guapcoin$MNID/guapcoin.conf.backup

# fix permissions
chown -R guapadmin:guapadmin /home/guapadmin/.guapcoin$MNID

# add new nodes to config file
sed -i '/addnode/d' ~/.guapcoin$MNID/guapcoin.conf

echo "addnode=159.65.221.182
addnode=45.76.255.103
addnode=209.250.250.121
addnode=138.197.136.6
addnode=198.199.68.111
addnode=178.62.110.207
addnode=155.138.140.38
addnode=45.76.199.11
addnode=70.35.194.41
addnode=144.202.75.140
addnode=209.126.5.122
addnode=95.216.27.40
addnode=104.236.14.155" >> ~/.guapcoin$MNID/guapcoin.conf

systemctl start guapcoin$MNID.service

TimeToWait=40
echo "Starting guapcoin$MNID.service, will check status in $TimeToWait seconds..."

for (( i = $TimeToWait; i > 0; i-- )); do
  clear
  echo "Starting guapcoin$MNID.service, will check status in $i seconds..."
  sleep 1
done

clear

if ! systemctl status guapcoin$MNID | grep -q "active (running)"; then
  echo "ERROR: Failed to start guapcoin$MNID.service. Please contact support. Exiting script."
  sleep 3
  exit
fi

echo "Waiting for wallet to load..."
until su -c "/usr/local/bin/guapcoin-cli -conf=/home/guapadmin/.guapcoin$MNID/guapcoin.conf -datadir=/home/guapadmin/.guapcoin$MNID getinfo 2>/dev/null | grep -q \"version\"" "$USER"; do
  sleep 1;
done

clear

echo "Your masternode MN at guapcoin$MNID.service is syncing. Please wait for this process to finish."
echo "This can take a while. Do not close this window."
echo ""



until [ -n "$(/usr/local/bin/guapcoin-cli -conf=/home/guapadmin/.guapcoin$MNID/guapcoin.conf -datadir=/home/guapadmin/.guapcoin$MNID getconnectioncount 2>/dev/null)"  ]; do
  sleep 1
done

until su -c "/usr/local/bin/guapcoin-cli -conf=/home/guapadmin/.guapcoin$MNID/guapcoin.conf -datadir=/home/guapadmin/.guapcoin$MNID mnsync status 2>/dev/null | grep '\"IsBlockchainSynced\": true' > /dev/null" "$USER"; do
  echo -ne "Current block: $(su -c "/usr/local/bin/guapcoin-cli -conf=/home/guapadmin/.guapcoin$MNID/guapcoin.conf -datadir=/home/guapadmin/.guapcoin$MNID getblockcount" "$USER")\\r"
  sleep 1
done

clear

cat << EOL

Now, you need to start your masternode. Follow the steps below:
1) Please go to your desktop wallet
2) Click the Masternodes tab
3) Click 'Start all' at the bottom or select your newly refreshed node and click 'Start Alias'.
EOL

read -p "Press Enter to continue after you've done that. " -n1 -s

clear

sleep 1

echo "" && echo "Masternode at guapcoin$MNID.service refresh completed." && echo ""
echo "" && echo "Please see details for the refreshed Masternode below:"
echo -ne "$(su -c "/usr/local/bin/guapcoin-cli -conf=/home/guapadmin/.guapcoin$MNID/guapcoin.conf -datadir=/home/guapadmin/.guapcoin$MNID getmasternodestatus" "$USER")\\r"
