#!/bin/bash
# GuapCoin Masternode Setup Script V2 for Ubuntu 16.04 LTS
#
# Script will attempt to autodetect primary public IP address
# and generate masternode private key unless specified in command line
#
# Usage:
# bash guapcoin.autoinstall.sh
#

#Color codes
RED='\033[0;91m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#TCP port
PORT=9633
RPC=9634

MNID=""
REINSTALL=""

#Clear keyboard input buffer
function clear_stdin { while read -r -t 0; do read -r; done; }

#Delay script execution for N seconds
function delay { echo -e "${GREEN}Sleep for $1 seconds...${NC}"; sleep "$1"; }

#Stop daemon if it's already running
function stop_daemon {
    if pgrep -x 'guapcoind' > /dev/null; then
        echo -e "${YELLOW}Attempting to stop guapcoind${NC}"
        guapcoin-cli stop
        sleep 30
        if pgrep -x 'guapcoind' > /dev/null; then
            echo -e "${RED}guapcoind daemon is still running!${NC} \a"
            echo -e "${RED}Attempting to kill...${NC}"
            sudo pkill -9 guapcoind
            sleep 30
            if pgrep -x 'guapcoind' > /dev/null; then
                echo -e "${RED}Can't stop guapcoind! Reboot and try again...${NC} \a"
                exit 2
            fi
        fi
    fi
}
#Function detect_ubuntu

 if [[ $(lsb_release -d) == *18.04* ]]; then
   UBUNTU_VERSION=18
else
   echo -e "${RED}You are not running Ubuntu 18.04, Installation is cancelled.${NC}"
   exit 1

fi

#Process command line parameters
genkey=$1
clear

echo -e "${GREEN} ------- Additional GuapCoin MASTERNODE INSTALLER v2.3.001--------+
 |                                                        |
 |                                                        |::
 |     This script will install an additional MN.         |
 |                                                        |
 | ------------------------------------------------------ |
 |                                                        |
 |  If you have NOT ALREADY INSTALLED a first MN on this  |
 |   VPS using the standard GUAP-v2-Ubunutu1804-VER2.sh   |
 |       script then this installer is not for you.       |
 |                                                        |
 |  It is assumed that at least one MN has been installed |
 |    on this VPS and that the guapcoin executables in    |
 |    /usr/local/bin are in place and are operational.    |
 |                                                        |
 |  It is also assumed that this VPS is setup with a new  |
 |      static IP which will be used for this new MN,     |
 |     and that the interface for the new IP is active.   |
 |   See your VPS documentation on additional static IP.  |


 +------------------------------------------------+::
   ::::::::::::::::::::::::::::::::::::::::::::::::::S${NC}"
echo "Do you want me to generate a masternode private key for you?[y/n]"
read DOSETUP

if [[ $DOSETUP =~ "n" ]] ; then
          read -e -p "Enter your private key:" genkey;
              read -e -p "Confirm your private key: " genkey2;
    fi

#Confirming match
  if [ $genkey = $genkey2 ]; then
     echo -e "${GREEN}MATCH! ${NC} \a"
else
     echo -e "${RED} Error: Private keys do not match. Try again or let me generate one for you...${NC} \a";exit 1
fi
sleep .5
clear

USER="guapadmin"
USERHOME=`eval echo "~$USER"`

# Determine primary public IP address
dpkg -s dnsutils 2>/dev/null >/dev/null || sudo apt-get -y install dnsutils
publicip=""
read -e -p "Enter VPS Public IP Address: " publicip


#if [ -n "$publicip" ]; then
#    echo -e "${YELLOW}IP Address detected:" $publicip ${NC}
#else
#    echo -e "${RED}ERROR: Public IP Address was not detected!${NC} \a"
#    clear_stdin
#    read -e -p "Enter VPS Public IP Address: " publicip
#    if [ -z "$publicip" ]; then
#        echo -e "${RED}ERROR: Public IP Address must be provided. Try again...${NC} \a"
#        exit 1
#    fi
#fi

if [ -d "/var/lib/fail2ban/" ];
then
    echo -e "${GREEN}Packages already installed...${NC}"
else
    echo -e "${GREEN}Updating system and installing required packages...${NC}"

sudo DEBIAN_FRONTEND=noninteractive apt-get update -y
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove
sudo apt-get -y install wget nano
sudo apt-get install unzip
fi

#Generating Random Password for  JSON RPC
rpcuser=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
rpcpassword=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

#ID existing MNs and setup for installing an additional one
while ! [ "$MNID" -eq "$MNID" ] 2> /dev/null
do
  echo "Enter the single digit number for this Masternode's ID#. It must not match the ID# of an existing MN on this VPS"
  echo "MNIDs for active masternodes detected on this VPS are:"

  MNarray[0]=0 #MNarray is used to idenitfy which MNs(and their corresponding MNIDs) are present, position #0 is a dummy location
  FILE1=/etc/systemd/system/guapcoin.service #let's test for MN1. if it exist then report that MNID as in use
  if test -f "$FILE1"; then
    MNarray[0]=1
    echo "0"
  fi


  for (( i = 1; i < 20; i++ )); do
      FILE=/etc/systemd/system/guapcoin$i.service
      if test -f "$FILE"; then
          MNarray[$i]=1
          echo "$i"
      fi
  done
  echo ""
  read -e -p "Please choose an ID# for your new Masternode that does not appear on the list of detected MNs above : " MNID

  # Make sure that $MNID is a number
  if ! [ "$MNID" -eq "$MNID" ] 2> /dev/null
  then
      echo ""
      echo "Sorry, the ID# must be a single integer."
      echo ""
      read -rp "Press any key to continue. " -n1 -s
      clear
      continue
  fi


echo ""
echo "Your chosen MNID is: $MNID"

  # Make sure that the masternode ID chosen is not already is use on this VPS.
  if [ "${MNarray["$MNID"]}" == "1" ] 2> /dev/null
  then
    #statements
    echo "Sorry, the ID# you've chosen corresponds to another MN detected on this VPS."
    echo ""
    read -e -p "Would you like to replace the current install for MN$MNID with a fresh install? Y/n : " REINSTALL

    if [ "$REINSTALL" == "Y" ] 2> /dev/null
    then

      echo ""
      echo "MN$MNID will be deleted and removed from the list."

      systemctl stop guapcoin$MNID
      sleep 4
      systemctl disable guapcoin$MNID
      sleep 2
      rm -r /home/guapadmin/.guapcoin$MNID
      rm -r /etc/systemd/system/guapcoin$MNID.service
      clear
      continue
    else

      read -rp "Press any key to continue and chose another. " -n1 -s
      echo ""
      echo ""
      MNID=""
      clear
      continue

    fi

  fi

  if [[ "$MNID" == "0" ]]; then
    #statements
    MNID=""
    #echo " test guapcoin$MNID"
  fi

done



#*********************** Assumes additional Masternode is being created; creates a .guapcoin$MNID dir and sets up the guapcoin$MNID.service *****************************************************


#Installing Daemon
cd ~
#rm -rf /usr/local/bin/guapcoin*
#wget https://github.com/guapcrypto/Guapcoin/releases/download/v2.0/Guapcoin-2.0-Daemon-Ubuntu_16.04.tar.gz
#tar -xzvf Guapcoin-2.0-Daemon-Ubuntu_16.04.tar.gz
#sudo chmod -R 755 guapcoin-cli
#sudo chmod -R 755 guapcoind
#cp -p -r guapcoind /usr/local/bin
#cp -p -r guapcoin-cli /usr/local/bin

#guapcoin-cli stop
#sleep 5


 #Create datadir for new MN
 sudo mkdir $USERHOME/.guapcoin$MNID


cd ~
clear
echo -e "${YELLOW}Creating guapcoin.conf...${NC}"

# If genkey was not supplied in command line, we will generate private key on the fly
if [ -z $genkey ]; then
    cat <<EOF > $USERHOME/.guapcoin$MNID/guapcoin.conf
rpcuser=$rpcuser
rpcpassword=$rpcpassword
EOF

    sudo chmod 755 -R $USERHOME/.guapcoin$MNID/guapcoin.conf

    #Starting daemon first time just to generate masternode private key
    guapcoind -daemon
sleep 7
while true;do
    echo -e "${YELLOW}Generating masternode private key...${NC}"
    genkey=$(guapcoin-cli createmasternodekey)
    if [ "$genkey" ]; then
        break
    fi
sleep 7
done
    fi



    #Stopping daemon to create guapcoin.conf
    #guapcoin-cli stop
    #sleep 5
cd $USERHOME/.guapcoin$MNID/ && rm -rf blocks chainstate sporks peers.dat
cd $USERHOME/.guapcoin$MNID/ && wget http://45.63.25.141/bootstrap.tar.gz
cd $USERHOME/.guapcoin$MNID/ && tar -xzvf bootstrap.tar.gz
# Create guapcoin.conf
cat <<EOF > $USERHOME/.guapcoin$MNID/guapcoin.conf
rpcuser=$rpcuser
rpcpassword=$rpcpassword
rpcallowip=::1
rpcport=5000$MNID
port=$PORT
listen=1
server=1
daemon=1
logtimestamps=1
maxconnections=256
masternode=1
externalip=$publicip
bind=$publicip
masternodeaddr=[$publicip]:9633
masternodeprivkey=$genkey
addnode=159.65.221.180
addnode=45.76.61.148
addnode=209.250.250.121
addnode=136.244.112.117
addnode=199.247.20.128
addnode=78.141.203.208
addnode=155.138.140.38
addnode=45.76.199.11
addnode=45.63.25.141


EOF





sudo chmod 755 -R ~/.guapcoin$MNID/guapcoin.conf
sudo chown -R $USER:$USER $USERHOME/.guapcoin$MNID


cat > /etc/systemd/system/guapcoin$MNID.service << EOL
[Unit]
Description=guapcoind MN$MNID
After=network.target
OnFailure=unit-status-alert@%n.service
[Service]
Type=forking
User=${USER}
WorkingDirectory=${USERHOME}
ExecStart=/usr/local/bin/guapcoind -conf=${USERHOME}/.guapcoin$MNID/guapcoin.conf -datadir=${USERHOME}/.guapcoin$MNID
ExecStop=/usr/local/bin/guapcoin-cli -conf=${USERHOME}/.guapcoin$MNID/guapcoin.conf -datadir=${USERHOME}/.guapcoin$MNID stop
Restart=on-abort
[Install]
WantedBy=multi-user.target
EOL

echo "Starting guapcoin$MNID service"
echo ""

sudo systemctl enable guapcoin$MNID.service
sudo systemctl start guapcoin$MNID.service

clear

cat << EOL

Now, you need to start your masternode. Please go to your desktop wallet
Click the Masternodes tab
Click Start all at the bottom
EOL

read -p "Press Enter to continue after you've done that. " -n1 -s

clear

#    guapcoind -daemon
#Finally, starting daemon with new guapcoin.conf
#printf '#!/bin/bash\nif [ ! -f "~/.guapcoin/guapcoin.pid" ]; then /usr/local/bin/guapcoind -daemon ; fi' > /root/guapcoinauto.sh
#chmod -R 755 guapcoinauto.sh
#Setting auto start cron job for guapcoin
#if ! crontab -l | grep "guapcoinauto.sh"; then
#    (crontab -l ; echo "*/5 * * * * /root/guapcoinauto.sh")| crontab -
#fi

echo -e "========================================================================
${GREEN}Additional Masternode setup is complete!${NC}
========================================================================
Masternode was installed with VPS IP Address: ${GREEN}$publicip${NC}
Masternode Private Key: ${GREEN}$genkey${NC}
Now you can add the following string to the masternode.conf file
======================================================================== \a"
echo -e "${GREEN}MN$MNID $publicip:$PORT $genkey TxId TxIdx${NC}"
echo -e "========================================================================
Use your mouse to copy the whole string above into the clipboard by
tripple-click + single-click (Dont use Ctrl-C) and then paste it
into your ${GREEN}masternode.conf${NC} file and replace:
    ${GREEN}MN$MNID${NC} - with your desired masternode name (alias)
    ${GREEN}TxId${NC} - with Transaction Id from getmasternodeoutputs
    ${GREEN}TxIdx${NC} - with Transaction Index (0 or 1)
     Remember to save the masternode.conf and restart the wallet!
To introduce your new masternode to the guapcoin network, you need to
issue a masternode start command from your wallet, which proves that
the collateral for this node is secured."

clear_stdin
read -p "*** Press any key to continue ***" -n1 -s
echo ""
echo -e "Wait for the node wallet on this VPS to sync with the other nodes
on the network. Eventually the 'Is Synced' status will change
to 'true', which will indicate a comlete sync, although it may take
from several minutes to several hours depending on the network state.
Your initial Masternode Status may read:
    ${GREEN}Node just started, not yet activated${NC} or
    ${GREEN}Node  is not in masternode list${NC}, which is normal and expected.
"
clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "
${GREEN}...scroll up to see previous screens...${NC}
Here are some useful commands and tools for masternode troubleshooting:
========================================================================
To view masternode configuration produced by this script in guapcoin.conf:
${GREEN}cat $USERHOME/.guapcoin$MNID/guapcoin.conf${NC}
Here is your guapcoin.conf generated by this script:
-------------------------------------------------${GREEN}"
echo -e "${GREEN}MN$MNID $publicip:$PORT $genkey TxId TxIdx${NC}"
cat $USERHOME/.guapcoin$MNID/guapcoin.conf
echo -e "${NC}-------------------------------------------------
NOTE: To edit guapcoin.conf, first stop the guapcoind daemon,
then edit the guapcoin.conf file and save it in nano: (Ctrl-X + Y + Enter),
then start the guapcoind daemon back up:
to stop:              ${GREEN}systemctl stop guapcoin$MNID ${NC}
to start:             ${GREEN}systemctl start guapcoin$MNID ${NC}
to edit:              ${GREEN}nano $USERHOME/.guapcoin$MNID/guapcoin.conf${NC}
to check mn status:   ${GREEN}guapcoin-cli -conf=${USERHOME}/.guapcoin$MNID/guapcoin.conf -datadir=${USERHOME}/.guapcoin$MNID getmasternodestatus${NC}
========================================================================
To monitor system resource utilization and running processes:
                   ${GREEN}htop${NC}
========================================================================
"
