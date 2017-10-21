#!/bin/bash
##########################################################
# T-Pot 16.10 install script                             #
# Ubuntu server 16.04.0x, x64                            #
#                                                        #
# v1.1 by av, DTAG 2017-07-03                            #
#                                                        #
# based on T-Pot 16.10 Community Edition Script          #
# v16.10.0 by mo, DTAG, 2016-12-03                       #
##########################################################


# Let's create a function for colorful output
fuECHO () {
local myRED=1
local myWHT=7
tput setaf $myRED
echo $1 "$2"
tput setaf $myWHT
}

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
# T-Pot 16.10 install script                             #
# for Ubuntu server 16.04.0x, x64                        #
##########################################################
Make sure the key-based SSH login for your normal user is working!
"

# check for superuser
if [[ $EUID -ne 0 ]]; then
    fuECHO "### This script must be run as root. Do not run via sudo! Script will abort!"
    exit 1
fi

echo -en "Which user do you usually work with?\nThis script is invoked by root, but what is your normal username?\n"
echo -n "Enter username: "
read myuser

# Make sure all the necessary prerequisites are met.
echo ""
echo "Checking prerequisites..."

# check if user exists
if ! grep -q $myuser /etc/passwd
	then
		fuECHO "### User '$myuser' not found. Script will abort!"
        exit 1
fi


# check if ssh daemon is running
sshstatus=$(service ssh status)
if [[ ! $sshstatus =~ "active (running)" ]];
	then
		echo "### SSH is not running. Script will abort!"
		exit 1
fi

# check for available, non-empty SSH key
if ! fgrep -qs ssh /home/$myuser/.ssh/authorized_keys
    then
        fuECHO "### No SSH key for user '$myuser' found in /home/$myuser/.ssh/authorized_keys.\n ### Script will abort!"
        exit 1
fi

# check for default SSH port
sshport=$(fgrep Port /etc/ssh/sshd_config|cut -d ' ' -f2)
if [ $sshport != 22 ];
    then
        fuECHO "### SSH port is not 22. Script will abort!"
        exit 1
fi

# check if pubkey authentication is active
if ! fgrep -q "PubkeyAuthentication yes" /etc/ssh/sshd_config
	then
		fuECHO "### Public Key Authentication is disabled /etc/ssh/sshd_config. \n ### Enable it by changing PubkeyAuthentication to 'yes'."
		exit 1
fi

# check for ubuntu 16.04. distribution
release=$(lsb_release -r|cut -d $'\t' -f2)
if [ $release != "16.04" ]
    then
        fuECHO "### Wrong distribution. Must be Ubuntu 16.04.*. Script will abort! "
        exit 1
fi

# Let's make sure there is a warning if running for a second time
if [ -f install.log ];
  then
        fuECHO "### Running more than once may complicate things. Erase install.log if you are really sure."
        exit 1
fi

# set locale
locale-gen "en_US.UTF-8"
export LC_ALL="en_US.UTF-8"


# Let's log for the beauty of it
set -e
exec 2> >(tee "install.err")
exec > >(tee "install.log")


echo "Everything looks OK..."
echo ""
clear
echo "##########################################################"
echo "#                                                        #"
echo "#     How do you want to proceed? Enter your choice.     #"
echo "#                                                        #"
echo "# 1 - T-Pot's STANDARD INSTALLATION                      #"
echo "#     Requirements: >=4GB RAM, >=64GB disk               #"
echo "#     Services: Cowrie, Dionaea, ElasticPot, Glastopf,   #"
echo "#     Honeytrap, ELK & Suricata                          #"
echo "#                                                        #"
echo "# 2 - T-Pot's HONEYPOTS ONLY (w/o INDUSTRIAL)            #"
echo "#     Requirements: >=3GB RAM, >=64GB disk               #"
echo "#     Services:                                          #"
echo "#     Cowrie, Dionaea, ElasticPot, Glastopf & Honeytrap  #"
echo "#                                                        #"
echo "# 3 - T-Pot's INDUSTRIAL EDITION                         #"
echo "#     Requirements: >=4GB RAM, >=64GB disk               #"
echo "#     Services: ConPot, eMobility, ELK & Suricata        #"
echo "#                                                        #"
echo "# 4 - T-Pot's FULL INSTALLATION                          #"
echo "#     Requirements: >=8GB RAM, >=128GB disk              #"
echo "#     Services: Everything                               #"
echo "#                                                        #"
echo "##########################################################"
echo ""
echo -n "Your choice: "
read choice
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
apt-get install apt-transport-https ca-certificates curl dialog dnsutils dstat ethtool genisoimage git htop libpam-google-authenticator lm-sensors ntp openssh-server syslinux pv vim apache2-utils apparmor nginx aufs-tools bash-completion build-essential  cgroupfs-mount docker.io glances html2text iptables iw libltdl7 man nginx-extras nodejs npm ntp openssl psmisc python-pip -y 

# Let's clean up apt
apt-get autoclean -y
apt-get autoremove -y

# Let's remove NGINX default website
fuECHO "### Removing NGINX default website."
[ -f /etc/nginx/sites-enabled ] && rm /etc/nginx/sites-enabled/default
[ -f /etc/nginx/sites-avaliable ] && rm /etc/nginx/sites-available/default
[ -f /usr/share/nginx/html/index.html ] && rm /usr/share/nginx/html/index.html

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
htpasswd -b -c /etc/nginx/nginxpasswd $myUSER $myPASS1
fuECHO

# Let's modify the sources list
sed -i '/cdrom/d' /etc/apt/sources.list

# Let's make sure SSH roaming is turned off (CVE-2016-0777, CVE-2016-0778)
fuECHO "### Let's make sure SSH roaming is turned off."
tee -a /etc/ssh/ssh_config <<EOF
UseRoaming no
EOF

# Let's generate a SSL certificate
fuECHO "### Generating a self-signed-certificate for NGINX."
fuECHO "### If you are unsure you can use the default values."
mkdir -p /etc/nginx/ssl
openssl req -nodes -x509 -sha512 -newkey rsa:8192 -keyout "/etc/nginx/ssl/nginx.key" -out "/etc/nginx/ssl/nginx.crt" -days 3650

# Installing alerta-cli, wetty
fuECHO "### Installing alerta-cli."
pip install --upgrade pip
pip install alerta
fuECHO "### Installing wetty."
[ ! -f /usr/bin/node ] && ln -s /usr/bin/nodejs /usr/bin/node
npm install https://github.com/t3chn0m4g3/wetty -g


# Let's add a new user
fuECHO "### Adding new user."
addgroup --gid 2000 tpot
adduser --system --no-create-home --uid 2000 --disabled-password --disabled-login --gid 2000 tpot


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

# Let's patch docker defaults, so we can run images as service
fuECHO "### Patching docker defaults."
tee -a /etc/default/docker <<EOF
DOCKER_OPTS="-r=false"
EOF

# Let's restart docker for proxy changes to take effect
systemctl restart docker
sleep 5


# getting t-pot git repo
fuECHO "### Cloning T-Pot Repository."
cwdir=$(pwd)
git clone https://github.com/dtag-dev-sec/tpotce -b 16.10
cp -R $cwdir/tpotce/installer/ $cwdir
rm -rf $cwdir/tpotce/
rm $cwdir/installer/install.sh $cwdir/installer/rc.local.install
cwdir=$cwdir/installer
cd $cwdir

# we need to create a couple of directories
mkdir -p /data/

# Let's make sure only myFLAVOR images will be downloaded and started
case $mode in
  HP)
    echo "### Preparing HONEYPOT flavor installation."
    cp $cwdir/data/imgcfg/hp_images.conf /data/images.conf
  ;;
  INDUSTRIAL)
    echo "### Preparing INDUSTRIAL flavor installation."
    cp $cwdir/data/imgcfg/industrial_images.conf /data/images.conf
  ;;
  TPOT)
    echo "### Preparing TPOT flavor installation."
    cp $cwdir/data/imgcfg/tpot_images.conf /data/images.conf
  ;;
  ALL)
    echo "### Preparing EVERYTHING flavor installation."
    cp $cwdir/data/imgcfg/all_images.conf /data/images.conf
  ;;
esac

# Let's load docker images
fuECHO "### Loading docker images. Please be patient, this may take a while."
for name in $(cat /data/images.conf)
    do
      docker pull dtagdevsec/$name:latest1610
    done

# Let's patch /etc/issue for t-pot autoinstall
sed -i '14,15d' $cwdir/etc/issue
echo "Container status is written to ~/docker-status" >> $cwdir/etc/issue

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
kernel.panic = 1
kernel.panic_on_oops = 1
EOF

# Let's add some conrjobs
fuECHO "### Adding cronjobs."
tee -a /etc/crontab <<EOF
# Determine running containers every 120s
*/2 * * * * 	root 	/usr/bin/status.sh > /home/$myuser/docker-status

# Check if containers and services are up
*/5 * * * * 	root 	/usr/bin/check.sh

# Example for alerta-cli IP update
#*/5 * * * *	root	alerta --endpoint-url http://<ip>:<port>/api delete --filters resource=<host> && alerta --endpoint-url http://<ip>:<port>/api send -e IP -r <host> -E Production -s ok -S T-Pot -t \$(cat /data/elk/logstash/mylocal.ip) --status open

# Check if updated images are available and download them
27 1 * * *  	root	for i in \$(cat /data/images.conf); do /usr/bin/docker pull dtagdevsec/\$i:latest1610; done

# Restart docker service and containers
27 3 * * * 	root 	/usr/bin/dcres.sh

# Delete elastic indices older than 90 days
27 4 * * *  root  /usr/bin/docker exec elk bash -c '/usr/local/bin/curator --host 127.0.0.1 delete indices --older-than 90 --time-unit days --timestring '%Y.%m.%d''

# Update IP and erase check.lock if it exists
27 15 * * * root /etc/rc.local

# Daily reboot
27 23 * * *	root	reboot

# Check for updated packages every sunday, upgrade and reboot
27 16 * * 0   root  apt-get autoclean -y; apt-get autoremove -y; apt-get update -y; apt-get upgrade -y; sleep 10; reboot
EOF

# Let's create some files and folders
fuECHO "### Creating some files and folders."
mkdir -p /data/conpot/log \
         /data/cowrie/log/tty/ /data/cowrie/downloads/ /data/cowrie/keys/ /data/cowrie/misc/ \
         /data/dionaea/log /data/dionaea/bistreams /data/dionaea/binaries /data/dionaea/rtp /data/dionaea/roots/ftp /data/dionaea/roots/tftp /data/dionaea/roots/www /data/dionaea/roots/upnp \
         /data/elasticpot/log \
         /data/elk/data /data/elk/log /data/elk/logstash/conf \
         /data/glastopf /data/honeytrap/log/ /data/honeytrap/attacks/ /data/honeytrap/downloads/ \
         /data/emobility/log \
         /data/ews/log /data/ews/conf /data/ews/dionaea /data/ews/emobility \
         /data/suricata/log /home/$myuser/.ssh/


# Let's take care of some files and permissions
chmod 500 $cwdir/bin/*
chmod 600 $cwdir/data/*
chmod 644 $cwdir/etc/issue
chmod 755 $cwdir/etc/rc.local
chmod 644 $cwdir/data/systemd/*

# Let's copy some files
tar xvfz $cwdir/data/elkbase.tgz -C /
cp $cwdir/data/elkbase.tgz /data/
cp -R $cwdir/bin/* /usr/bin/
cp -R $cwdir/data/* /data/
cp    $cwdir/data/systemd/* /etc/systemd/system/
cp    $cwdir/etc/issue /etc/
cp -R $cwdir/etc/nginx/ssl /etc/nginx/
cp    $cwdir/etc/nginx/tpotweb.conf /etc/nginx/sites-available/
cp    $cwdir/etc/nginx/nginx.conf /etc/nginx/nginx.conf
cp    $cwdir/usr/share/nginx/html/* /usr/share/nginx/html/
cp    $cwdir/usr/share/dict/* /usr/share/dict/

# Let's set the hostname
fuECHO "### Setting a new hostname."
a=$(fuRANDOMWORD /usr/share/dict/a.txt)
n=$(fuRANDOMWORD /usr/share/dict/n.txt)
myHOST=$a$n
hostnamectl set-hostname $myHOST
sed -i 's#127.0.1.1.*#127.0.1.1\t'"$myHOST"'#g' /etc/hosts

for i in $(cat /data/images.conf);
  do
    systemctl enable $i;
done
systemctl enable wetty

# Let's enable T-Pot website
fuECHO "### Enabling T-Pot website."
ln -s /etc/nginx/sites-available/tpotweb.conf /etc/nginx/sites-enabled/tpotweb.conf

# Let's take care of some files and permissions
chmod 760 -R /data
chown tpot:tpot -R /data
chmod 600 /home/$myuser/.ssh/authorized_keys
chown $myuser:$myuser /home/$myuser/.ssh /home/$myuser/.ssh/authorized_keys

# Let's replace "quiet splash" options, set a console font for more screen canvas and update grub
sed -i 's#GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"#GRUB_CMDLINE_LINUX_DEFAULT="consoleblank=0"#' /etc/default/grub
sed -i 's#GRUB_CMDLINE_LINUX=""#GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"#' /etc/default/grub
#sed -i 's#\#GRUB_GFXMODE=640x480#GRUB_GFXMODE=800x600x32#' /etc/default/grub
#tee -a /etc/default/grub <<EOF
#GRUB_GFXPAYLOAD=800x600x32
#GRUB_GFXPAYLOAD_LINUX=800x600x32
#EOF
update-grub
cp /usr/share/consolefonts/Uni2-Terminus12x6.psf.gz /etc/console-setup/
gunzip /etc/console-setup/Uni2-Terminus12x6.psf.gz
sed -i 's#FONTFACE=".*#FONTFACE="Terminus"#' /etc/default/console-setup
sed -i 's#FONTSIZE=".*#FONTSIZE="12x6"#' /etc/default/console-setup
update-initramfs -u

# Let's enable a color prompt
myROOTPROMPT='PS1="\[\033[38;5;8m\][\[$(tput sgr0)\]\[\033[38;5;1m\]\u\[$(tput sgr0)\]\[\033[38;5;6m\]@\[$(tput sgr0)\]\[\033[38;5;4m\]\h\[$(tput sgr0)\]\[\033[38;5;6m\]:\[$(tput sgr0)\]\[\033[38;5;5m\]\w\[$(tput sgr0)\]\[\033[38;5;8m\]]\[$(tput sgr0)\]\[\033[38;5;1m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"'
myUSERPROMPT='PS1="\[\033[38;5;8m\][\[$(tput sgr0)\]\[\033[38;5;2m\]\u\[$(tput sgr0)\]\[\033[38;5;6m\]@\[$(tput sgr0)\]\[\033[38;5;4m\]\h\[$(tput sgr0)\]\[\033[38;5;6m\]:\[$(tput sgr0)\]\[\033[38;5;5m\]\w\[$(tput sgr0)\]\[\033[38;5;8m\]]\[$(tput sgr0)\]\[\033[38;5;2m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"'
tee -a /root/.bashrc << EOF
$myROOTPROMPT
EOF
tee -a /home/$myuser/.bashrc << EOF
$myUSERPROMPT
EOF

# Let's create ews.ip before reboot and prevent race condition for first start
myLOCALIP=$(hostname -I | awk '{ print $1 }')
myEXTIP=$(curl myexternalip.com/raw)
sed -i "s#IP:.*#IP: $myLOCALIP, $myEXTIP#" /etc/issue
sed -i "s#SSH:.*#SSH: ssh -l $myuser -p 64295 $myLOCALIP#" /etc/issue
sed -i "s#WEB:.*#WEB: https://$myLOCALIP:64297#" /etc/issue

tee /data/ews/conf/ews.ip << EOF
[MAIN]
ip = $myEXTIP
EOF
echo $myLOCALIP > /data/elk/logstash/mylocal.ip
chown $myuser:$myuser /data/ews/conf/ews.ip

# change user for wetty 
sed -i 's/tsec/'$myuser'/' /etc/systemd/system/wetty.service
sed -i 's/tsec/'$myuser'/' /usr/share/nginx/html/navbar.html
systemctl daemon-reload

# Final steps
fuECHO "### Thanks for your patience. Now rebooting. Remember to login on SSH port 64295 next time or visit dashboard at port 64297!"
mv $cwdir/etc/rc.local /etc/rc.local && rm -rf $cwdir && sleep 2 &&reboot
