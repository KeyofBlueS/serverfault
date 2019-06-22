# serverfault

# Version:    1.0.0
# Author:     KeyofBlueS
# Repository: https://github.com/KeyofBlueS/serverfault
# License:    GNU General Public License v3.0, https://opensource.org/licenses/GPL-3.0

### DESCRIPTION
This bash script check if a given server on LAN is online and sends a visual and acoustic warning to client. If any remote NFS/SSHFS remote mounts are unreachable they'll be unmounted (if root permissions are granted).

### INSTALL
```sh
curl -o /tmp/serverfault.sh 'https://raw.githubusercontent.com/KeyofBlueS/serverfault/master/serverfault.sh'
curl -o /tmp/serverfaultalarm 'https://raw.githubusercontent.com/KeyofBlueS/serverfault/master/serverfaultalarm'
sudo mkdir -p /opt/serverfault/
sudo mv /tmp/serverfault.sh /opt/serverfault/
sudo chown root:root /opt/serverfault/serverfault.sh
sudo chmod 755 /opt/serverfault/serverfault.sh
sudo chmod +x /opt/serverfault/serverfault.sh
sudo ln -s /opt/serverfault/serverfault.sh /usr/local/bin/serverfault
mv /tmp/serverfaultalarm $HOME/.serverfaultalarm
```

### USAGE

You need the connection uuid to the server (check your connection uuid with "nmcli connection show") and the ip address of the server on LAN you want to check:
```sh
$ serverfault --conn <uuid> --server <ip>
```
Options --conn <uuid> and --server <ip> in commandline can be omitted by compiling the USER CONFIGURATION at the top of this script (${0})

This tool is designed to start at boot time with cron and user root (in order to unmount unreachable remote mounts)
To configure crontab with user root, on a shell give:
```sh
$ sudo crontab -e
```
Cronjob example:
```
PATH=/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin
@reboot serverfault --conn <uuid> --server <ip> > /dev/null 2>&1 &
```

If you dont mind checking unreachable remote mounts, you could use cron with by user.
To configure crontab with normal user, on a shell give:
```sh
$ crontab -e
```
Cronjob example:
```
PATH=/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin
@reboot serverfault --conn <uuid> --server <ip> --nomountscheck > /dev/null 2>&1 &
```
For acoustic alarm you must put an audio file named .serverfault in your $HOME directory
```
Options:
--conn <uuid>	-c <uuid>	Enter the <uuid> of connection with server. Check your connection uuid with "nmcli connection show".
--server <ip>	-s <ip>		Enter the <ip> address of the server on LAN to check. You can enter multiple IPs, MUST BE separed by spaces and MUST BE enclosed in double quotes.
--nomountscheck	-n		Disable unreachable remote mounts check (default if user running this script is not root).
--noalarm	-o		Disable visual and acoustic alarm.
--interval <n>	-i <n>		Interval of <n> seconds before check if server is online (default 10).
--gain <n>	-g <n>		Alarm volume. Insert any negative or positive number e.g. -20, 0, 10, +20 (default -50).
--help		-h		Show description and help of serverfault.
```
