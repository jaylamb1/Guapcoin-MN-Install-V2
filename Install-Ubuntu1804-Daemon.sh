#!/bin/bash

#Installing Daemon
cd ~
rm -rf /usr/local/bin/guapcoin*
wget https://github.com/guapcrypto/Guapcoin/releases/download/v2.0.1/Guapcoin-2.0.1-Daemon-Ubuntu_18.04.tar.gz
tar -xzvf Guapcoin-2.0.1-Daemon-Ubuntu_18.04.tar.gz
sudo chmod -R 755 guapcoin-cli
sudo chmod -R 755 guapcoind
cp -p -r guapcoind /usr/local/bin
cp -p -r guapcoin-cli /usr/local/bin
