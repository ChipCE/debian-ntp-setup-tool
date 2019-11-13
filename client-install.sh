echo "ntp client setup tool v1.0"

# root check
FILE="/tmp/out.$$"
GREP="/bin/grep"

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root! command：sudo ./client-install.sh" 1>&2
   exit 1
fi

# disable timesyncd
echo "Trying to stop and disable timesyncd..."
systemctl stop systemd-timesyncd
systemctl disable systemd-timesyncd
echo "Trying to install ntp..."
apt-get install ntp

serverIpAddr=""
read -p "NTP server IP address : " serverIpAddr
while ! [[ $serverIpAddr =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
do
    echo "Error : invalid IP address!"
    echo "$serverIpAddr"
    read -p "NTP server IP address : " serverIpAddr
done

yes | cp -vrf ntp.conf.client ntp.conf.client.tmp
sed -i 's/#@server/server/' ntp.conf.client.tmp
sed -i 's,'"#@ip"','"$serverIpAddr"',' ntp.conf.client.tmp

echo "Copy config file..."
yes | cp -vrf ntp.conf.client.tmp /etc/ntp.conf
# stop ntpd (just in case)
sudo systemctl stop ntp
sleep 5
echo "Force ntp update..."
ntp -gq
sleep 10
echo "Start ntp client daemon."
sudo systemctl enable ntp
sleep 5
sudo systemctl start ntp
sleep 5
sudo systemctl status ntp
echo "Done."
exit 0