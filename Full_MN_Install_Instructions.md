# How to Install a Masternode Using Existing GUAP

For those that are interested please see below instructions for setting up a MN on your desktop wallet using your existing GUAP. Setting up a masternode requires creating a masternode wallet on a virtual private server and setting up a masternode controller on your desktop wallet.

#### Background Info on MN (skip if you are familiar with MNs and their general setup)
  A masternode is simply a node (or wallet: remember that each wallet that is on and connected to the GUAP network becomes a node in the blockchain) that is always on and connected, and takes on certain important roles on the blockchain (such as facilitating instant transactions) and in return gets a reward from time to time.

  The most secure way to run a masternode is to use two wallets (this is standard and suggested setup used for GUAP). First there is a cold wallet where you lock up your 10,000 GUAP and receive the MN rewards (this is the masternode controller and is typically your desktop wallet), and second there is the hot wallet that is the 24/7 always connected wallet that usually runs on a virtual private server (this is the masternode). 

  Both are needed, but once setup and started the cold wallet (which is your desktop wallet) need not be on all the time, and really only needs to be opened once in a while to sync to the blockchain and collect all your rewards earned since the last sync. For the masternode (the always on hot wallet) you need only a single core 1Ghz machine with about 2GB of ram and 30-40GB in storage available. It is also advise that you set up a swapfile.

  PLEASE NOTE that the hot wallet needs to been connected to the internet and the blockchain 24/7, so relying on your home internet connection for this purpose puts your masternode and the GUAP network at risk (remember that masternodes contribute to the robustness and speed of the GUAP network). Additionally desktop operating systems like Windows and MacOS are not designed for high availability always services and application, server systems are best for that. Best practice is to run the masternode from a virtual private server on a service like Vultr (https://www.vultr.com/) and DigitalOcean (https://www.digitalocean.com/). Right now it cost about $10/month to run a VPS on Vultr with the above specs and get your masternode going (these are linux systems and the linux versions of the wallet run on Ubuntu 18.04). The cold wallet (desktop wallet with the masternode controller) can run on any Mac or PC made within the last few years without any issue (there are desktop wallets available for Windows, Mac and Linux desktop operating systems).

#### See full instructions below.

NOTE: Note that these instructions are provided AS IS, do not provide for every eventuality or problem that might arise, do not include every detail of every sub-step, and you are on your own regarding support or fixes related to using these instructions. Also note that your VPS is a linux system that will need to be periodically updated and maintained, and your masternode wallet is linux application that will sometimes have issues and possibly crash just like any other piece of software. There’s a multitude of resources available online for maintaining the performance and security of linux systems and applications. I suggest getting familiar with them.

Now onto the instructions.




## 1. First you must setup a virtual private server:

### System requirements - USE AN UBUNTU LINUX 18.04 VPS for best results.

The VPS you plan to install your masternode on needs to have at least 2GB of RAM and 10GB of free disk space. We do not recommend using servers who do not meet those criteria because your masternode may become stable. 

We also recommend you do not use elastic cloud services like AWS or Google Cloud for your masternode - to use your node with such a service would require some networking knowledge and manual configuration. Vultr (https://www.vultr.com/) and DigitalOcean (https://www.digitalocean.com/) are good options. 

Once you've created your account and started your VPS instance, make note of the root password and the IP address of the instance (Vultr calls these 'Instances' and DigitOcean calls these 'Droplets').




## 2. Then you need to fund your Masternode controller address on the cold/desktop wallet:
### Funding your Masternode.

First, we will do the initial collateral transaction (TX) and send exactly 10,000 GUAP to a newly created addresses on the desktop wallet. 
To keep things sorted in case we setup more masternodes we will label the addresses we create and use.

- Open your GUAP wallet and on 'RECEIVE' to bring up the “Receive” tab.

- Click the 'Generate Address' button to create a new address.

- Click on 'Edit Label' to create a label for this new address; Let's use “MN1".


The generated address will now be labeled as MN1. If you want to setup more masternodes just repeat the steps above so you end up with several addresses for the total number of nodes you wish to setup. Example: For 10 nodes you will need 10 addresses (make sure you label them all).

Once all addresses are created send exactly 10,000 GUAP each to them. Ensure that you send exactly 10,000 GUAP and do it in a single transaction. You can double check where the coins are coming from by checking it via coin control.

As soon as all 10K transactions are done, we will wait for 15 confirmations. You can check this in your wallet or use the explorer (https://guapexplorer.com/). It should take 15 - 30 minutes to get 15 confirmations for all of the new addresses.



## 3. Installation & Setting up your Masternode Controller on the cold/desktop wallet:
### Generate your Masternode Private Key.

- In your wallet, open Settings -> Debug -> Console and run the following command to get your masternode key:

    `createmasternodekey`

    Please note: If you plan to set up more than one masternode, you need to create a key with the above command for each one.

- Run this command to get your output information:

    `getmasternodeoutputs`

- Copy both the key and output information to a text file. For the output information you will need the 'txhash' and the 'outputidx'. 

### Add your Masternode Key and Txid to masternode.conf.
- Close your wallet and open the Guapcoin Appdata folder. Its location depends on your OS.

    Windows: Press Windows+R and write %APPDATA%\Guapcoin there. Clock 'OK' to open the folder Guapcoin.

    macOS: Press Command+Space to open Spotlight, write ~/Library/Application Support/Guapcoin and press Enter.

    Linux: Open ~/.Guapcoin/

- In your appdata folder, open the masternode.conf file with a text editor and add a new line in this format to the bottom of the file:

    *masternodename ipaddress:9633 masternodekey txhash outputidx*

    An example would be:
    
    *MN1 127.0.0.2:9633 93HaYBVUCYjEMeeH1Y4sBGLALQZE1Y 2bcd3c84c84f87eaa86e4e56hgjgf5214521834c929 0*

    *masternodename* is a name you choose and should correspond to the label to chose above for the MN controller address, *ipaddress* is the public IP of your VPS, *masternodekey* is the output from runnning the `createmasternodekey` command earlier, and txhash  & outputidx come from running the `getmasternodeoutputs` earlier. Please note that *masternodename* must not contain any spaces, and should not contain any special characters.
    
- Restart and unlock your wallet.



## 4. Install the Masternode server on the hot/VPS wallet:

- SSH into to your VPS server as root using the public IP of VPS (using Putty on Windows, Terminal.app on macOS, or any other ssh client of your choice). Please note: It’s normal that you don’t see your password after typing or pasting it when logging in through SSH. Run the following commands:

  `wget -q https://raw.githubusercontent.com/guapcrypto/Guapcoin-MN-Install-2.3.0.1/master/GUAP-v2.3.0.1-MN.sh`
  
  `sudo chmod +x GUAP-v2.3.0.1-MN.sh`
  
  `./GUAP-v2.3.0.1-MN.sh`


- When the script asks, paste in and then confirm your masternodekey. 

- Next type in the public IP address of your VPS

- The installer may present you with a few options. Carefully follow the instructions on screen. At some point the script will instruction you 'Start' the masternode on the cold/desktop wallet. Once you do so that masternode will go to 'ACTIVE', and after some time (1-2 hrs usually) will go to 'ENABLED'.

- After the basic installation is done, the wallet will sync.

- Once you see “Masternode Successfully Started” on screen, you are done.

- The masternode that you started and that became 'ACTIVE' will after some time(1-2 hrs usually) will go to 'ENABLED'. Once it is 'ENABLED' that masternode will be in the mix to recieve masternode rewards. See the explorer for the current average amount of time it takes for masternodes to receive rewards once they are 'ENABLED' (see the Average Masternode Payment graph at https://guapexplorer.com/#/masternode). 


