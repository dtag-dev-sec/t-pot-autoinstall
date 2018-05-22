#!/bin/bash
##########################################################
# T-Pot 17.10 install script                             #
# Ubuntu server 16.04.0x, x64                            #
#                                                        #
# v1.2 by av, DTAG 2017-11-13                            #
#                                                        #
# based on T-Pot 17.10 Community Edition Script          #
# v17.10.0 by mo, DTAG, 2016-10-19                       #
##########################################################


# Let's create a function for colorful output
fuECHO () {
local myRED=1
local myWHT=7
tput setaf $myRED
echo $1 "$2"
tput setaf $myWHT
}

# Some global vars
myTPOTCOMPOSE="/opt/tpot/etc/tpot.yml"
cwdir=$(pwd)


# used for hostname
fuRANDOMWORD () {
  local myWORDFILE="$1"
  local myLINES=$(cat $myWORDFILE  | wc -l)
  local myRANDOM=$((RANDOM % $myLINES))
  local myNUM=$((myRANDOM * myRANDOM % $myLINES + 1))
  echo -n $(sed -n "$myNUM p" $myWORDFILE | tr -d \' | tr A-Z a-z)
}


fuECHO ""
echo "
##########################################################
# T-Pot 17.10 install script                             #
# for Ubuntu server 16.04.0x, x64                        #
##########################################################
Make sure the key-based SSH login for your normal user is working!
"

# ADD ARGS for automated setup
if [ "$#" -ne 3 -a  "$#" -gt 0 ]; then    
	echo "## Please add the following three arguments for a one shot install:"
    echo "         Username, which edition to install (number), a webpassword"
    echo "## invoke: $0 myusername <1|2|3|4> myWebPassw0rd"
    echo ""
    echo "## Editions to choose from: "
    echo "##########################################################"
	echo "#                                                        #"
	echo "#     How do you want to proceed? Enter your choice.     #"
	echo "#                                                        #"
	echo "#     Required: 4GB RAM, 64GB disk                       #"
	echo "#     Recommended: 8GB RAM, 128GB SSD                    #"
	echo "#                                                        #"
	echo "# 1 - T-Pot's STANDARD INSTALLATION                      #"
	echo "#     Standard Honeypots, Suricata & ELK                 #"
	echo "#                                                        #"
	echo "# 2 - T-Pot's HONEYPOTS ONLY                             #"
	echo "#     Honeypots only, w/o Suricata & ELK                 #"
	echo "#                                                        #"
	echo "# 3 - T-Pot's INDUSTRIAL EDITION                         #"
	echo "#     Conpot, eMobility, Suricata & ELK                  #"
	echo "#                                                        #"
	echo "# 4 - T-Pot's FULL INSTALLATION                          #"
	echo "#     Everything                                         #"
	echo "#                                                        #"
	echo "##########################################################"
	echo ""
    echo "## EXITING"
    exit 1
fi

if [ "$#" -eq 3 ]; then
        myusergiven=$1
        myeditiongiven=$2
        mypasswordgiven=$3
        echo "## Installing non interactive using"
        echo "## User: $myusergiven"
        echo "## Edition: $myeditiongiven"
        echo "## Webpassword: $mypasswordgiven"
        echo "## Let's see if that works..." 
        noninteractive=1
fi

# check for superuser
if [[ $EUID -ne 0 ]]; then
    fuECHO "### This script must be run as root. Do not run via sudo! Script will abort!"
    exit 1
fi


if [ -z ${noninteractive+x} ]; then
	echo -en "Which user do you usually work with?\nThis script is invoked by root, but what is your normal username?\n"
	echo -n "Enter username: "
	read myuser
else
	myuser=$myusergiven
fi 


# Make sure all the necessary prerequisites are met.
echo ""
echo "Checking prerequisites..."

# check if user exists
if ! grep -q $myuser /etc/passwd
	then
		fuECHO "### User '$myuser' not found. Script will abort!"
        exit 1
fi


# check for ubuntu 16.04. distribution
release=$(lsb_release -r|cut -d $'\t' -f2)
if [ $release != "16.04" ]
    then
        fuECHO "### Wrong distribution. Must be Ubuntu 16.04.*. Script will abort! "
        exit 1
fi


# set locale
locale-gen "en_US.UTF-8"
export LC_ALL="en_US.UTF-8"


# Let's log for the beauty of it
set -e
exec 2> >(tee "install.err")
exec > >(tee "install.log")

apt install python-setuptools

echo "Everything looks OK..."
echo ""
clear


if [ -z ${noninteractive+x} ]; then
	echo "##########################################################"
	echo "#                                                        #"
	echo "#     How do you want to proceed? Enter your choice.     #"
	echo "#                                                        #"
	echo "#     Required: 4GB RAM, 64GB disk                       #"
	echo "#     Recommended: 8GB RAM, 128GB SSD                    #"
	echo "#                                                        #"
	echo "# 1 - T-Pot's STANDARD INSTALLATION                      #"
	echo "#     Standard Honeypots, Suricata & ELK                 #"
	echo "#                                                        #"
	echo "# 2 - T-Pot's HONEYPOTS ONLY                             #"
	echo "#     Honeypots only, w/o Suricata & ELK                 #"
	echo "#                                                        #"
	echo "# 3 - T-Pot's INDUSTRIAL EDITION                         #"
	echo "#     Conpot, eMobility, Suricata & ELK                  #"
	echo "#                                                        #"
	echo "# 4 - T-Pot's FULL INSTALLATION                          #"
	echo "#     Everything                                         #"
	echo "#                                                        #"
	echo "##########################################################"
	echo ""
	echo -n "Your choice: "
	read choice
else 
	choice=$myeditiongiven
fi


if [[ "$choice" != [1-4] ]];
	then
		fuECHO "### You typed $choice, which I don't recognize. It's either '1', '2', '3' or '4'. Script will abort!"
		exit 1
fi
case $choice in
1)
	echo "You chose T-Pot's STANDARD INSTALLATION. The best default ever!"
	mode="TPOT"
	;;
2)
	echo "You chose to install T-Pot's HONEYPOTS ONLY. Ack."
	mode="HP"
	;;
3)
	echo "You chose T-Pot's INDUSTRIAL EDITION. ICS is the new IOT."
	mode="INDUSTRIAL"
	;;
4)
	echo "You chose to install T-Pot's FULL INSTALLATION. Bring it on..."
	mode="ALL"
	;;

*)
	fuECHO "### You typed $choice, which I don't recognize. It's either '1', '2', '3' or '4'. Script will abort!"
	exit 1
	;;
esac


# End checks

# Let's pull some updates
fuECHO "### Pulling Updates."
apt-get update -y
fuECHO "### Installing Updates."
apt-get upgrade -y

# Install packages needed

apt-get install apache2-utils apparmor apt-transport-https aufs-tools bash-completion build-essential ca-certificates cgroupfs-mount curl dialog dnsutils docker.io dstat ethtool genisoimage git glances html2text htop iptables iw jq libcrack2 libltdl7 lm-sensors man nginx-extras nodejs npm ntp openssh-server openssl prips syslinux psmisc pv python-pip unzip vim -y 

# Let's clean up apt
apt-get autoclean -y
apt-get autoremove -y

# Let's remove NGINX default website
fuECHO "### Removing NGINX default website."
[ -e /etc/nginx/sites-enabled ] && rm /etc/nginx/sites-enabled/default  
[ -e /etc/nginx/sites-avaliable ] && rm /etc/nginx/sites-available/default  
[ -e /usr/share/nginx/html/index.html ] && rm /usr/share/nginx/html/index.html  

if [ -z ${noninteractive+x} ]; then
	# Let's ask user for a password for the web user
	myOK="n"
	myUSER=$myuser
	fuECHO "### Please enter a password for your user $myuser for web access."
	myPASS1="pass1"
	myPASS2="pass2"
	while [ "$myPASS1" != "$myPASS2"  ] 
	  do
		while [ "$myPASS1" == "pass1"  ] || [ "$myPASS1" == "" ]
		  do
			read -s -p "Password: " myPASS1
			fuECHO
		  done
		read -s -p "Repeat password: " myPASS2
		fuECHO
		if [ "$myPASS1" != "$myPASS2" ];
		  then
			fuECHO "### Passwords do not match."
			myPASS1="pass1"
			myPASS2="pass2"
		fi
	  done
else 
	myUSER=$myusergiven
	myPASS1=$mypasswordgiven
fi
htpasswd -b -c /etc/nginx/nginxpasswd $myUSER $myPASS1 
fuECHO

# Let's modify the sources list
sed -i '/cdrom/d' /etc/apt/sources.list

# Let's make sure SSH roaming is turned off (CVE-2016-0777, CVE-2016-0778)
fuECHO "### Let's make sure SSH roaming is turned off."
tee -a /etc/ssh/ssh_config  <<EOF
UseRoaming no
EOF

# Let's generate a SSL certificate
fuECHO "### Generating a self-signed-certificate for NGINX."
fuECHO "### If you are unsure you can use the default values."
mkdir -p /etc/nginx/ssl 
openssl req -nodes -x509 -sha512 -newkey rsa:8192 -keyout "/etc/nginx/ssl/nginx.key" -out "/etc/nginx/ssl/nginx.crt" -days 3650  -subj '/C=AU/ST=Some-State/O=Internet Widgits Pty Ltd'

# Installing docker-compose, wetty, ctop, elasticdump, tpot
pip install --upgrade pip
fuECHO "### Installing docker-compose."
pip install docker-compose==1.16.1 
fuECHO "### Installing elasticsearch curator."
pip install elasticsearch-curator==5.2.0
fuECHO "### Installing wetty."
[ ! -e /usr/bin/node ] && ln -s /usr/bin/nodejs /usr/bin/node 
npm install https://github.com/t3chn0m4g3/wetty -g 
fuECHO "### Installing elasticsearch-dump."
npm install https://github.com/t3chn0m4g3/elasticsearch-dump -g 
fuECHO "### Installing ctop."
wget https://github.com/bcicen/ctop/releases/download/v0.6.1/ctop-0.6.1-linux-amd64 -O ctop 
mv ctop /usr/bin/
chmod +x /usr/bin/ctop
fuECHO "### Cloning T-Pot."
git clone https://github.com/dtag-dev-sec/tpotce /opt/tpot

# Let's add a new user
fuECHO "### Adding new user."
addgroup --gid 2000 tpot
adduser --system --no-create-home --uid 2000 --disabled-password --disabled-login --gid 2000 tpot


# Let's set the hostname
a=$(fuRANDOMWORD /opt/tpot/host/usr/share/dict/a.txt)
n=$(fuRANDOMWORD /opt/tpot/host/usr/share/dict/n.txt)
myHOST=$a$n
hostnamectl set-hostname $myHOST 
sed -i 's#127.0.1.1.*#127.0.1.1\t'"$myHOST"'#g' /etc/hosts 


# Let's patch sshd_config
fuECHO "### Patching sshd_config to listen on port 64295 and deny password authentication."
sed -i 's#Port 22#Port 64295#' /etc/ssh/sshd_config
sed -i 's#\#PasswordAuthentication yes#PasswordAuthentication no#' /etc/ssh/sshd_config

# Let's allow ssh password authentication from RFC1918 networks
fuECHO "### Allow SSH password authentication from RFC1918 networks"
tee -a /etc/ssh/sshd_config <<EOF

Match address 127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
    PasswordAuthentication yes
EOF

# we need to create a couple of directories
mkdir -p /data/

# Let's make sure only myFLAVOR images will be downloaded and started
case $mode in
  HP)
    echo "### Preparing HONEYPOT flavor installation."
    cp /opt/tpot/etc/compose/hp.yml $myTPOTCOMPOSE 
  ;;
  INDUSTRIAL)
    echo "### Preparing INDUSTRIAL flavor installation."
    cp /opt/tpot/etc/compose/industrial.yml $myTPOTCOMPOSE
  ;;
  TPOT)
    echo "### Preparing TPOT flavor installation."
    cp /opt/tpot/etc/compose/tpot.yml $myTPOTCOMPOSE
  ;;
  ALL)
    echo "### Preparing EVERYTHING flavor installation."
    cp /opt/tpot/etc/compose/all.yml $myTPOTCOMPOSE
  ;;
esac


# Let's load docker images
myIMAGESCOUNT=$(cat $myTPOTCOMPOSE | grep -v '#' | grep image | cut -d: -f2 | wc -l)
j=0
for name in $(cat $myTPOTCOMPOSE | grep -v '#' | grep image | cut -d'"' -f2)
  do
    docker pull $name 
    let j+=1
  done
  
# Let's add the daily update check with a weekly clean interval
fuECHO "### Modifying update checks."
tee /etc/apt/apt.conf.d/10periodic <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::AutocleanInterval "7";
EOF

# Let's make sure to reboot the system after a kernel panic
fuECHO "### Reboot after kernel panic."
tee -a /etc/sysctl.conf <<EOF

# Reboot after kernel panic, check via /proc/sys/kernel/panic[_on_oops]
# Set required map count for ELK
kernel.panic = 1
kernel.panic_on_oops = 1
vm.max_map_count = 262144
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF


# Let's add some conrjobs
fuECHO "### Adding cronjobs."
tee -a /etc/crontab <<EOF
# Check if updated images are available and download them
27 1 * * *      root    docker-compose -f /opt/tpot/etc/tpot.yml pull
# Delete elasticsearch logstash indices older than 90 days
27 4 * * *      root    curator --config /opt/tpot/etc/curator/curator.yml /opt/tpot/etc/curator/actions.yml
# Uploaded binaries are not supposed to be downloaded
*/1 * * * *     root    mv --backup=numbered /data/dionaea/roots/ftp/* /data/dionaea/binaries/
# Daily reboot
27 3 * * *      root    reboot
# Check for updated packages every sunday, upgrade and reboot
27 16 * * 0     root    apt-get autoclean -y && apt-get autoremove -y && apt-get update -y && apt-get upgrade -y && sleep 10 && reboot
EOF

# Let's create some files and folders
fuECHO "### Creating some files and folders."
mkdir -p /data/conpot/log \
         /data/cowrie/log/tty/ /data/cowrie/downloads/ /data/cowrie/keys/ /data/cowrie/misc/ \
         /data/dionaea/log /data/dionaea/bistreams /data/dionaea/binaries /data/dionaea/rtp /data/dionaea/roots/ftp /data/dionaea/roots/tftp /data/dionaea/roots/www /data/dionaea/roots/upnp \
         /data/elasticpot/log \
         /data/elk/data /data/elk/log \
         /data/glastopf /data/honeytrap/log/ /data/honeytrap/attacks/ /data/honeytrap/downloads/ \
         /data/mailoney/log \
         /data/emobility/log \
         /data/ews/conf \
         /data/rdpy/log \
         /data/spiderfoot \
         /data/suricata/log /home/$myuser/.ssh/ \
         /data/p0f/log \
         /data/vnclowpot/log
touch /data/spiderfoot/spiderfoot.db 

# Let's copy some files
tar xvfz /opt/tpot/etc/objects/elkbase.tgz -C / 
cp    /opt/tpot/host/etc/systemd/* /etc/systemd/system/ 
cp    /opt/tpot/host/etc/issue /etc/ 
cp -R /opt/tpot/host/etc/nginx/ssl /etc/nginx/ 
cp    /opt/tpot/host/etc/nginx/tpotweb.conf /etc/nginx/sites-available/
cp    /opt/tpot/host/etc/nginx/nginx.conf /etc/nginx/nginx.conf 
cp    /opt/tpot/host/usr/share/nginx/html/* /usr/share/nginx/html/ 
systemctl enable tpot 
systemctl enable wetty

# patch wetty config
sed -e 's:tsec:'$myuser':g' -i /etc/systemd/system/wetty.service

# patch html navbar
sed -e 's:tsec:'$myuser':g' -i /usr/share/nginx/html/navbar.html


# Let's enable T-Pot website
ln -s /etc/nginx/sites-available/tpotweb.conf /etc/nginx/sites-enabled/tpotweb.conf 

# Let's take care of some files and permissions
chmod 760 -R /data 
chown tpot:tpot -R /data 
chmod 600 /home/$myuser/.ssh/authorized_keys 
chown $myuser:$myuser /home/$myuser/.ssh /home/$myuser/.ssh/authorized_keys 

# Let's replace "quiet splash" options, set a console font for more screen canvas and update grub
sed -i 's#GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"#GRUB_CMDLINE_LINUX_DEFAULT="consoleblank=0"#' /etc/default/grub
sed -i 's#GRUB_CMDLINE_LINUX=""#GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"#' /etc/default/grub
update-grub
cp /usr/share/consolefonts/Uni2-Terminus12x6.psf.gz /etc/console-setup/
gunzip /etc/console-setup/Uni2-Terminus12x6.psf.gz
sed -i 's#FONTFACE=".*#FONTFACE="Terminus"#' /etc/default/console-setup
sed -i 's#FONTSIZE=".*#FONTSIZE="12x6"#' /etc/default/console-setup
update-initramfs -u 

# Let's enable a color prompt and add /opt/tpot/bin to path
myROOTPROMPT='PS1="\[\033[38;5;8m\][\[$(tput sgr0)\]\[\033[38;5;1m\]\u\[$(tput sgr0)\]\[\033[38;5;6m\]@\[$(tput sgr0)\]\[\033[38;5;4m\]\h\[$(tput sgr0)\]\[\033[38;5;6m\]:\[$(tput sgr0)\]\[\033[38;5;5m\]\w\[$(tput sgr0)\]\[\033[38;5;8m\]]\[$(tput sgr0)\]\[\033[38;5;1m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"'
myUSERPROMPT='PS1="\[\033[38;5;8m\][\[$(tput sgr0)\]\[\033[38;5;2m\]\u\[$(tput sgr0)\]\[\033[38;5;6m\]@\[$(tput sgr0)\]\[\033[38;5;4m\]\h\[$(tput sgr0)\]\[\033[38;5;6m\]:\[$(tput sgr0)\]\[\033[38;5;5m\]\w\[$(tput sgr0)\]\[\033[38;5;8m\]]\[$(tput sgr0)\]\[\033[38;5;2m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"'
tee -a /root/.bashrc  <<EOF
$myROOTPROMPT
PATH="$PATH:/opt/tpot/bin"
EOF
tee -a /home/$myuser/.bashrc <<EOF
$myUSERPROMPT
PATH="$PATH:/opt/tpot/bin"
EOF

# Let's create ews.ip before reboot and prevent race condition for first start
/opt/tpot/bin/updateip.sh


# Final steps
fuECHO "### Thanks for your patience. Now rebooting. Remember to login on SSH port 64295 next time or visit the dashboard on port 64297!"
mv /opt/tpot/host/etc/rc.local /etc/rc.local && sleep 2 && reboot
