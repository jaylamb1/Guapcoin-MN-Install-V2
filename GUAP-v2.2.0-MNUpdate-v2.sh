#/bin/bash

sudo apt-get -y install unzip

while ! [ "$MNID" -eq "$MNID" ] 2> /dev/null
do
  echo "Enter the single digit Masternode ID# for the MN you want to update."
  echo "MNIDs for active masternodes detected on this VPS are:"
  MNarray[0]=0 #test for .guapcoin
  Starti=0
  FILE=/etc/systemd/system/guapcoin.service

  if test -f "$FILE"; then
      MNarray[0]=1
      echo "0"
      Starti=1
  fi

  for (( i = $Starti; i < 12; i++ )); do
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

echo "Stopping service for active masternodes"
sleep 1

for (( i = 0; i < 12; i++ )); do
    if [[ "$MNarray[$i]" == "1" ]]; then
        guapcoin-cli -conf=/home/guapadmin/.guapcoin$i/guapcoin.conf -datadir=/home/guapadmin/.guapcoin$i stop
        systemctl stop guapcoin$i.service
        echo "service  guapcoin$i stopped"
        echo ""
    fi
done

echo "Your GuapCoin Masternode, ID=$MNID, Will be Updated To Version 2.2.0 Now"

#systemctl stop guapcoin$MNID.service
sleep 10
rm -rf /usr/local/bin/guapcoin*
mkdir GUAP_2.2.0
cd GUAP_2.2.0
wget https://github.com/guapcrypto/Guapcoin/releases/download/v2.2.0/Guapcoin-2.2.0-Daemon-Ubuntu.tar.gz
tar -xzvf Guapcoin-2.2.0-Daemon-Ubuntu.tar.gz
mv guapcoind /usr/local/bin/guapcoind
mv guapcoin-cli /usr/local/bin/guapcoin-cli
chmod +x /usr/local/bin/guapcoin*
rm -rf /home/guapadmin/.guapcoin$MNID/blocks
rm -rf /home/guapadmin/.guapcoin$MNID/chainstate
rm -rf /home/guapadmin/.guapcoin$MNID/sporks
rm -rf /home/guapadmin/.guapcoin$MNID/peers.dat
cd /home/guapadmin/.guapcoin$MNID/
wget http://45.63.25.141/bootstrap.tar.gz
tar -xzvf bootstrap.tar.gz

cd ..
rm -rf /home/guapadmin/.guapcoin$MNID/.guapcoin/bootstrap.tar.gz ~/GUAP_2.2.0
systemctl start guapcoin$MNID.service
sleep 10

guapcoin-cli -conf=/home/guapadmin/.guapcoin$MNID/guapcoin.conf -datadir=/home/guapadmin/.guapcoin$MNID addnode 159.65.221.180 onetry
guapcoin-cli -conf=/home/guapadmin/.guapcoin$MNID/guapcoin.conf -datadir=/home/guapadmin/.guapcoin$MNID addnode 45.76.61.148 onetry
guapcoin-cli -conf=/home/guapadmin/.guapcoin$MNID/guapcoin.conf -datadir=/home/guapadmin/.guapcoin$MNID addnode 209.250.250.121 onetry
guapcoin-cli -conf=/home/guapadmin/.guapcoin$MNID/guapcoin.conf -datadir=/home/guapadmin/.guapcoin$MNID addnode 136.244.112.117 onetry
guapcoin-cli -conf=/home/guapadmin/.guapcoin$MNID/guapcoin.conf -datadir=/home/guapadmin/.guapcoin$MNID addnode 199.247.20.128 onetry
guapcoin-cli -conf=/home/guapadmin/.guapcoin$MNID/guapcoin.conf -datadir=/home/guapadmin/.guapcoin$MNID addnode 78.141.203.208 onetry
guapcoin-cli -conf=/home/guapadmin/.guapcoin$MNID/guapcoin.conf -datadir=/home/guapadmin/.guapcoin$MNID addnode 155.138.140.38 onetry
guapcoin-cli -conf=/home/guapadmin/.guapcoin$MNID/guapcoin.conf -datadir=/home/guapadmin/.guapcoin$MNID addnode 45.76.199.11 onetry
guapcoin-cli -conf=/home/guapadmin/.guapcoin$MNID/guapcoin.conf -datadir=/home/guapadmin/.guapcoin$MNID addnode 45.63.25.141 onetry
guapcoin-cli -conf=/home/guapadmin/.guapcoin$MNID/guapcoin.conf -datadir=/home/guapadmin/.guapcoin$MNID addnode 108.61.252.179 onetry
guapcoin-cli -conf=/home/guapadmin/.guapcoin$MNID/guapcoin.conf -datadir=/home/guapadmin/.guapcoin$MNID addnode 155.138.219.187 onetry
guapcoin-cli -conf=/home/guapadmin/.guapcoin$MNID/guapcoin.conf -datadir=/home/guapadmin/.guapcoin$MNID addnode 66.42.93.170 onetry

echo "Masternode $MNID Updated!"
echo "Please wait few minutes and start your Masternode again on your Local Wallet"
