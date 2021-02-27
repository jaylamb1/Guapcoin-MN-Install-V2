#/bin/bash

sudo apt-get -y install unzip

USER="guapadmin"
USERHOME=`eval echo "~$USER"`


echo "Your GuapCoin daemon Will be Updated To Version 2.3.1 Now"


sleep 10
rm -rf /usr/local/bin/guapcoin*
mkdir GUAP_2.3.1
cd GUAP_2.3.1
wget https://github.com/guapcrypto/Guapcoin-MN-Install-2.3.0.1/raw/master/Guapcoin-2.3.0.1-Daemon-Ubuntu.tar.gz
tar -xzvf Guapcoin-2.3.0.1-Daemon-Ubuntu.tar.gz
mv guapcoind /usr/local/bin/guapcoind
mv guapcoin-cli /usr/local/bin/guapcoin-cli
chmod +x /usr/local/bin/guapcoin*

echo "Guapcoin daemon has been pdated to version 2.3.1!"
echo "Please run refresh on each MN installed on this vps"
