#/bin/bash

sudo apt-get -y install unzip

USER="guapadmin"
USERHOME=`eval echo "~$USER"`


echo "Your GuapCoin daemon Will be Updated To Version 2.3.2 Now"


sleep 10

rm -rf /usr/local/bin/guapcoin*
mkdir GUAP_2.3.2
cd GUAP_2.3.2
wget https://github.com/guapcrypto/Guap-v2.3.2-MN/releases/download/v2.3.2/Guapcoin-2.3.2-Ubuntu18.04-daemon.tar.gz
tar -xzvf Guapcoin-2.3.2-Ubuntu18.04-daemon.tar.gz
mv guapcoind /usr/local/bin/guapcoind
mv guapcoin-cli /usr/local/bin/guapcoin-cli
chmod +x /usr/local/bin/guapcoin*



echo "Guapcoin daemon has been pdated to version 2.3.2!"
echo "Please run MN-refresh-V232.sh on each MN installed on this vps"
