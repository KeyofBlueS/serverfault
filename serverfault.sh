#!/bin/bash

# Version:    1.0.0
# Author:     KeyofBlueS
# Repository: https://github.com/KeyofBlueS/serverfault
# License:    GNU General Public License v3.0, https://opensource.org/licenses/GPL-3.0

############################################## USER CONFIGURATION ###########################################################################
# Set to "true" to enable autoupdate of this script
UPDATE=true

#WARNING: Options --server (-s) and --connection (-c) in commandline, if valid, will overcome the user configuration below.

# Enter the <uuid> of connection with server. Check your connection uuid with "nmcli connection show"
# example: UUID_CONNECTION=c8afe685-d824-4b62-92dd-bf2886db9190
UUID_CONNECTION=

# Enter the IP address of the server on LAN to check.
# example: SERVERIP=192.168.0.100
# You can enter multiple IPs, MUST BE separed by spaces and MUST BE enclosed in double quotes:
# example: SERVERIP="192.168.0.100 192.168.1.100 192.168.1.120"
# It's recommended to set a static IP on the server.
SERVERIP=

########################################### END OF USER CONFIGURATION ########################################################################

if echo $UPDATE | grep -Eq '^(true|True|TRUE|si|NO|no)$'; then
echo -e "\e[1;34mCheck for updates...\e[0m"
if curl -s github.com > /dev/null; then
	SCRIPT_LINK="https://raw.githubusercontent.com/KeyofBlueS/serverfault/master/serverfault.sh"
	UPSTREAM_VERSION="$(timeout -s SIGTERM 15 curl -L "$SCRIPT_LINK" 2> /dev/null | grep "# Version:" | head -n 1)"
	LOCAL_VERSION="$(cat "${0}" | grep "# Version:" | head -n 1)"
	REPOSITORY_LINK="$(cat "${0}" | grep "# Repository:" | head -n 1)"
	if echo "$LOCAL_VERSION" | grep -q "$UPSTREAM_VERSION"; then
		echo -e "\e[1;32m
## This script is synced with upstream version
\e[0m
"
	else
		echo -e "\e[1;33m-----------------------------------------------------------------------------------	
## WARNING: this script is not synced with upstream version, visit:
\e[1;32m$REPOSITORY_LINK

\e[1;33m$LOCAL_VERSION (locale)
\e[1;32m$UPSTREAM_VERSION (upstream)
\e[1;33m-----------------------------------------------------------------------------------

\e[1;35mHit ENTER to update this script or wait 10 seconds to exit
\e[1;31m## WARNING: any custom changes will be lost!!!
\e[0m
"
		if read -t 10 _e; then
			echo -e "\e[1;34m	Updating...\e[0m"
			if [[ -L "${0}" ]]; then
				scriptpath="$(readlink -f "${0}")"
			else
				scriptpath="${0}"
			fi
			if [ -z "${scriptfolder}" ]; then
				scriptfolder="${scriptpath}"
				if ! [[ "${scriptpath}" =~ ^/.*$ ]]; then
					if ! [[ "${scriptpath}" =~ ^.*/.*$ ]]; then
					scriptfolder="./"
					fi
				fi
				scriptfolder="${scriptfolder%/*}/"
				scriptname="${scriptpath##*/}"
			fi
			if timeout -s SIGTERM 15 curl -s -o /tmp/"${scriptname}" "$SCRIPT_LINK"; then
				if [[ -w "${scriptfolder}${scriptname}" ]] && [[ -w "${scriptfolder}" ]]; then
					mv /tmp/"${scriptname}" "${scriptfolder}"
					chown root:root "${scriptfolder}${scriptname}" > /dev/null 2>&1
					chmod 755 "${scriptfolder}${scriptname}" > /dev/null 2>&1
					chmod +x "${scriptfolder}${scriptname}" > /dev/null 2>&1
				elif which sudo > /dev/null 2>&1; then
					while true
					do
					echo -e "\e[1;33mIn order to update you must grant root permissions\e[0m"
					if sudo -v; then
						break
					else
						echo -e "\e[1;31mPermission denied! Press ENTER to retry or wait 5 seconds to exit\e[0m"
						if read -t 5 _e; then
							exit 1
						fi
					fi
					done
					sudo mv /tmp/"${scriptname}" "${scriptfolder}"
					sudo chown root:root "${scriptfolder}${scriptname}" > /dev/null 2>&1
					sudo chmod 755 "${scriptfolder}${scriptname}" > /dev/null 2>&1
					sudo chmod +x "${scriptfolder}${scriptname}" > /dev/null 2>&1
				else
					echo -e "\e[1;31m	Error during update!
Permission denied!
\e[0m"
				fi
			else
				echo -e "\e[1;31m	Download error!
\e[0m"
			fi
			LOCAL_VERSION="$(cat "${0}" | grep "# Version:" | head -n 1)"
			if echo "$LOCAL_VERSION" | grep -q "$UPSTREAM_VERSION"; then
				echo -e "\e[1;34m	Done!
\e[0m"
				exec "${scriptfolder}${scriptname}"
			else
				echo -e "\e[1;31m	Error during update!
\e[0m"
			fi
		fi
	fi
fi
fi

# Checking dependencies
for name in fping grep nmap nmcli pgrep sox sudo whoami yad
do
if which $name > /dev/null; then
	echo -n
else
	if [ "${name}" = "nmcli" ]; then
		name="network-manager"
	fi
	if [ "${name}" = "pgrep" ]; then
		name="procps"
	fi
	if [ "${name}" = "whoami" ]; then
		name="coreutils"
	fi
	if [ -z "${missing}" ]; then
		missing="$name"
	else
		missing="$missing $name"
	fi
fi
done
if ! [ -z "${missing}" ]; then
	echo -e "\e[1;31mThis script requires \e[1;34m$missing\e[1;31m. Use \e[1;34msudo apt-get install $missing
\e[1;31mInstall the requested dependencies and restart this script.\e[0m"
	exit 1
fi

initialize(){
# Check configuration

if ! [ -z "${UUID_CONNECTION}" ]; then
	if nmcli -f uuid connection show | grep -E "$UUID_CONNECTION" | awk '{print $1}' | grep -Exq "$UUID_CONNECTION"; then
		echo -n
	else
		echo -e "\e[1;31mERROR: The uuid connection \e[1;34m$UUID_CONNECTION \e[1;31mdoes not exist.
Please configure one of the below uuid connection in \e[1;34m"$(readlink -f "${0}")"\e[1;31m.\e[0m"
		nmcli connection show
		exit 1
	fi
else
	echo -e "\e[1;31mERROR: The uuid connection is not configured.
Please configure one of the below uuid connection in \e[1;34m"$(readlink -f "${0}")"\e[1;31m.\e[0m"
nmcli connection show
exit 1
fi

if ! [ -z "${SERVERIP}" ]; then
	if echo $SERVERIP | grep -Eoq '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'; then
		echo -n
	else
		echo -e "\e[1;31mERROR: The IP address \e[1;34m$SERVERIP \e[1;31mis not valid.
Please configure a valid IP address in \e[1;34m"$(readlink -f "${0}")"\e[1;31m.\e[0m"
		exit 1
	fi
else
	echo -e "\e[1;31mERROR: The IP address is not configured.
Please configure a valid IP address in \e[1;34m"$(readlink -f "${0}")"\e[1;31m.\e[0m"
exit 1
fi

# Check if root permission needed
user=$(whoami)
processpath="${0}"
processname="${processpath##*/}"
if echo $STEP | grep -xq "servercheck"; then
	echo -n
else
	if [ "${user}" = "root" ]; then
		echo -e "\e[1;32mProcess owned by $user\e[0m"
	else
		echo -e "\e[1;33m - WARNING: Unreachable remote mounts check is not active.
To enable unreachable remote mounts check please run $processname with root privileges and without options (e.g. \e[1;34msudo $processname\e[1;33m)\e[0m"
		STEP=servercheck
#		givemehelp
	fi
fi

# Check if old process exist and kill it
for pid in $(pgrep "$processname"); do
	if [ "${pid}" != $$ ]; then
		echo -e "\e[1;34mA process $processname ($pid) is running yet. I'll try to terminate it...\e[0m"
		kill -9 $pid
		if [ $? != 0 ]; then
			processuser="$(ps -o user= -p $pid)"
			if [ "${processuser}" != "$user" ]; then
				echo -e "\e[1;31mUnable to terminate the process as is owned by user "$processuser".\e[0m"
				while true
				do
				echo -e "\e[1;33mTo terminate the process $processname ($pid) you must grant root permissions:\e[0m"
				if sudo -v; then
					sudo kill -9 $pid
					sudo -K
					break
				else
					echo -e "\e[1;31mPermission denied! Press ENTER to retry or wait 10 seconds to exit\e[0m"
					if read -t 10 _e; then
						echo -n
					else
						exit 1
					fi
				fi
				done
			else
				echo -e "\e[1;31mERROR: Unable to terminate the process $processname ($pid).\e[0m"
				exit 1
			fi
		fi
	fi
done

# Check if user is logged
while true
do
date
	USER_NAME="$(who -q | grep -v '#' | awk '{print $1}')"
	if echo $USER_NAME | grep -Eq '^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$'; then
#		echo -e "\e[1;34mLogged user is $USER_NAME\e[0m"
		break
	else
		echo -e "\e[1;33mNo user logged\e[0m"
		sleep 1
	fi
done

# Check if old warning exist and kill it
if pgrep -f "yad --text=########## SERVER OFFLINE ##########*" > /dev/null; then
	pkill -15 -f "yad --text=########## SERVER OFFLINE ##########*"
fi

echo Connection is: "$(nmcli connection show | grep "$UUID_CONNECTION")"
echo Server IP is: $SERVERIP

# setting interval
if echo $INTERVAL | grep -Poq '\d+'; then
	echo -n
else
	INTERVAL=10
fi
echo INTERVAL is: $INTERVAL seconds

# setting gain
if echo $GAIN | grep -Eq '^[+]?[0-9]+$'; then
	echo -n
elif echo $GAIN | grep -Eq '^-[0-9]+$'; then
	echo -n
else
	GAIN=-50
fi
echo GAIN is: $GAIN dB

# setting alarm
ALARM="/home/$USER_NAME/.serverfaultalarm"
CONFIG="/tmp/.noalarm"
if echo $BELL | grep -xq "OFF"; then
	touch $CONFIG
else
	BELL=ON
	if [ -e $CONFIG ]; then
		rm $CONFIG
	fi
fi
echo ALARM is: $BELL

#clear
servercheck
}

servercheck(){
date
if pgrep -f "yad --text=########## SERVER OFFLINE ##########*" > /dev/null; then
	pkill -15 -f "yad --text=########## SERVER OFFLINE ##########*"
fi
while true
do
	USER_NAME="$(who -q | grep -v '#' | awk '{print $1}')"
	if echo $USER_NAME | grep -Eq '^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$'; then
		echo -e "\e[1;34mLogged user is $USER_NAME\e[0m"
		break
	else
		echo -e "\e[1;33mNo user logged\e[0m"
		sleep 1
	fi
done
if nmcli -t -f uuid connection show --active | grep -q "$UUID_CONNECTION"; then
	echo -e "\e[1;32mConnection is UP\e[0m"
	if fping -r 10 -B 1.0 $SERVERIP | grep -q "alive"; then
		echo -e "\e[1;32mServer is ONLINE\e[0m"
	else
		echo -e "\e[1;31mServer is OFFLINE\e[0m"
		if [ -e $CONFIG ]; then
			echo -e "\e[1;33mALARM IS OFF\e[0m"
		else
			echo -e "\e[1;34mALARM IS ON\e[0m"
			if [ "${user}" = "root" ]; then
				sudo -u $USER_NAME DISPLAY=:0.0 timeout 30 yad --text="########## SERVER OFFLINE ##########" --center --title="WARNING" --image  "dialog-warning" --no-buttons --sticky --on-top &
			else
				DISPLAY=:0.0 timeout 30 yad --text="########## SERVER OFFLINE ##########" --center --title="WARNING" --image  "dialog-warning" --no-buttons --sticky --on-top &
			fi
			if [ -e $ALARM ]; then
				play -q $ALARM gain $GAIN
			else
				echo -e "\e[1;33m - WARNING: No alarm file found. Please put a sound file named .serverfaultalarm.wav in your HOME directory\e[0m"
			fi
		fi
		if [ "${STEP}" = "servercheck" ]; then
			echo -e "\e[1;33m - WARNING: Unreachable remote mounts check is not active.
To enable unreachable remote mounts check please run $processname with root privileges and without options (e.g. \e[1;34msudo $processname\e[1;33m)
\e[1;34mChecking in $INTERVAL seconds...\e[0m"
			sleep $INTERVAL
		fi	
		$STEP
	fi
else
	echo -e "\e[1;33mConnection is DOWN\e[0m"
	if [ "${STEP}" = "servercheck" ]; then
		echo -e "\e[1;33m - WARNING: Unreachable remote mounts check is not active.
To enable unreachable remote mounts check please run $processname with root privileges and without options (e.g. \e[1;34msudo $processname\e[1;33m)
\e[1;34mChecking in $INTERVAL seconds...\e[0m"
		sleep $INTERVAL
	fi	
	$STEP
fi
echo -e "\e[1;34mChecking in $INTERVAL seconds...\e[0m"
sleep $INTERVAL
servercheck
}

mountscheck(){
# check if umount locked process exist and kill it
while true
do
echo -e "\e[1;34mchecking umount and umount.nfs4* locked processes...\e[0m"
if pgrep -f "/sbin/umount.nfs4*" > /dev/null; then
	if ! [ -z $NFS_MOUNTS ]; then
		for NFS_MOUNT in $NFS_MOUNTS
		do
			echo -e "\e[1;31m - kill umount and umount.nfs4 for $NFS_MOUNT\e[0m"
			pkill -9 -f "umount -f -l $NFS_MOUNT" > /dev/null
			pkill -9 -f "/sbin/umount.nfs4 $NFS_MOUNT*" > /dev/null
		done
		sleep 0.2
	fi
else
	echo -e "\e[1;32m - no umount and umount.nfs4* processes running\e[0m"
	break
fi
done
# check for unreachable NFS filesystems and unmount it
while true
do
echo -e "\e[1;34mchecking remote NFS unreachable mounts$NFS_AGAIN...\e[0m"
NFS_MOUNTS_IPS="$(mount | grep "nfs" | grep -Eo '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)' | uniq)"
if echo $NFS_MOUNTS_IPS | grep -Eoq '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)'; then
	if nmcli -t -f uuid connection show --active | grep -q "$UUID_CONNECTION"; then
		NFS_MOUNTS_UNREACHABLE_IPS="$(nmap -v -n -sn $NFS_MOUNTS_IPS | grep "host down" | grep -Eo '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)')"
	else
		NFS_MOUNTS_UNREACHABLE_IPS="$(fping -q -u -r 10 -B 1.0 $NFS_MOUNTS_IPS)"
	fi
	if echo $NFS_MOUNTS_UNREACHABLE_IPS | grep -Eoq '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)'; then
		echo -e "\e[1;31m - unmounting unreachable NFS filesystems:\e[0m"
		for NFS_MOUNTS_UNREACHABLE_IP in $NFS_MOUNTS_UNREACHABLE_IPS
		do
			NFS_MOUNTS="$(mount | grep "nfs" | grep "$NFS_MOUNTS_UNREACHABLE_IP" | awk -F'on ' '{print $2}' | awk '{print $1}')"
			for NFS_MOUNT in $NFS_MOUNTS
			do
				echo -e "\e[1;33m -- $NFS_MOUNT\e[0m"
				timeout -s SIGKILL 10 umount -f -l $NFS_MOUNT &
			done
		done
		NFS_AGAIN=" again"
		sleep 1
	else
		echo -e "\e[1;32m - No unreachable NFS filesystems mounted\e[0m"
		NFS_AGAIN=""
		break
	fi
else
	echo -e "\e[1;32m - No NFS filesystems mounted\e[0m"
	NFS_AGAIN=""
	break
fi
done
# check for unreachable SSHFS filesystems and unmount it
while true
do
echo -e "\e[1;34mchecking remote SSHFS unreachable mounts$SSHFS_AGAIN...\e[0m"
SSHFS_MOUNTS_IPS="$(mount | grep "sshfs" | grep -Eo '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)' | uniq)"
if echo $SSHFS_MOUNTS_IPS | grep -Eoq '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)'; then
	if nmcli -t -f uuid connection show --active | grep -q "$UUID_CONNECTION"; then
		SSHFS_MOUNTS_UNREACHABLE_IPS="$(nmap -v -n -sn $SSHFS_MOUNTS_IPS | grep "host down" | grep -Eo '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)')"
	else
		SSHFS_MOUNTS_UNREACHABLE_IPS="$(fping -q -u -r 10 -B 1.0 $SSHFS_MOUNTS_IPS)"
	fi
	if echo $SSHFS_MOUNTS_UNREACHABLE_IPS | grep -Eoq '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)'; then
		echo -e "\e[1;31m - unmounting unreachable SSHFS filesystems:\e[0m"
		for SSHFS_MOUNTS_UNREACHABLE_IP in $SSHFS_MOUNTS_UNREACHABLE_IPS
		do
			SSHFS_MOUNTS="$(mount | grep "sshfs" | grep "$SSHFS_MOUNTS_UNREACHABLE_IP" | awk -F'on ' '{print $2}' | awk '{print $1}')"
			for SSHFS_MOUNT in $SSHFS_MOUNTS
			do
				echo -e "\e[1;33m -- $SSHFS_MOUNT\e[0m"
				timeout -s SIGKILL 10 fusermount -u $SSHFS_MOUNTS &
			done
		done
		SSHFS_AGAIN=" again"
		sleep 1
	else
		echo -e "\e[1;32m - No unreachable SSHFS filesystems mounted\e[0m"
		SSHFS_AGAIN=""
		break
	fi
else
	echo -e "\e[1;32m - No unreachable SSHFS filesystems mounted\e[0m"
	SSHFS_AGAIN=""
	break
fi
done
# check if umount locked process exist and kill it
while true
do
echo -e "\e[1;34mchecking umount and umount.nfs4* locked processes...\e[0m"
if pgrep -f "/sbin/umount.nfs4*" > /dev/null; then
	if ! [ -z $NFS_MOUNTS ]; then
		for NFS_MOUNT in $NFS_MOUNTS
		do
			echo -e "\e[1;31m - kill umount and umount.nfs4 for $NFS_MOUNT\e[0m"
			pkill -9 -f "umount -f -l $NFS_MOUNT"
			pkill -9 -f "/sbin/umount.nfs4 $NFS_MOUNT*"
		done
		sleep 0.2
	fi
else
	echo -e "\e[1;32m - no umount and umount.nfs4* processes running\e[0m"
	break
fi
done
# finish
echo -e "\e[1;34mChecking in $INTERVAL seconds...\e[0m"
sleep $INTERVAL
servercheck
}

givemehelp(){
echo "
# serverfault

# Version:    1.0.0
# Author:     KeyofBlueS
# Repository: https://github.com/KeyofBlueS/serverfault
# License:    GNU General Public License v3.0, https://opensource.org/licenses/GPL-3.0

### DESCRIPTION
This bash script check if a given server on LAN is offline and sends a visual and acoustic warning to client. If any remote NFS/SSHFS mounts are unreachable they'll be unmounted (if root permissions are granted).

### USAGE

You need the connection <uuid> to the server (check your connection uuid with "nmcli connection show") and the <ip> address of the server on LAN you want to check:

$ serverfault --conn <uuid> --server <ip>

Options --conn <uuid> and --server <ip> in commandline can be omitted by compiling the USER CONFIGURATION at the top of this script (${0})

This tool is designed to start at boot time with cron and user root (in order to unmount unreachable remote mounts)
To configure crontab with user root, on a shell give:

$ sudo crontab -e

Cronjob example:

PATH=/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin
@reboot serverfault --conn <uuid> --server <ip> > /dev/null 2>&1 &


If you dont mind checking unreachable remote mounts, you could use cron with unprivileged user.
To configure crontab with unprivileged user, on a shell give:

$ crontab -e

Cronjob example:

PATH=/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin
@reboot serverfault --conn <uuid> --server <ip> --nomountscheck > /dev/null 2>&1 &

For acoustic alarm you must put an audio file named .serverfault in your $HOME directory

Options:
--conn <uuid>	-c <uuid>	Enter the <uuid> of connection with server. Check your connection uuid with "nmcli connection show".
--server <ip>	-s <ip>		Enter the <ip> address of the server on LAN to check. You can enter multiple IPs, MUST BE separed by spaces and MUST BE enclosed in double quotes.
--nomountscheck	-n		Disable unreachable remote mounts check (default if user running this script is not root).
--noalarm	-o		Disable visual and acoustic alarm.
--interval <n>	-i <n>		Interval of <n> seconds before check if server is online (default 10).
--gain <n>	-g <n>		Alarm volume. Insert any negative or positive number e.g. -20, 0, 10, +20 (default -50).
--help		-h		Show description and help of serverfault.
"
exit 0
}

for opt in "$@"; do
	shift
	case "$opt" in
		'--conn')		set -- "$@" '-c' ;;
		'--server')		set -- "$@" '-s' ;;
		'--interval')		set -- "$@" '-i' ;;
		'--gain')		set -- "$@" '-g' ;;
		'--nomountscheck')	set -- "$@" '-n' ;;
		'--noalarm')		set -- "$@" '-o' ;;
		'--help')		set -- "$@" '-h' ;;
		*)                      set -- "$@" "$opt"
	esac
done

while getopts ":c:s:i:g:noh" opt; do
	case ${opt} in
		c ) if nmcli -f uuid connection show | grep -E "$OPTARG" | awk '{print $1}' | grep -Exq "$OPTARG"; then
			UUID_CONNECTION=$OPTARG
		else
			echo -e "\e[1;33m - WARNING: The uuid connection \e[1;34m$OPTARG \e[1;33mdoes not exist.
I'll try to use the user configuration if present.\e[0m"
		fi
		;;
		s ) if echo $OPTARG | grep -Eoq '(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'; then
			SERVERIP=$OPTARG
		else
			echo -e "\e[1;33m - WARNING: The IP address \e[1;34m$OPTARG \e[1;33mis not valid.
I'll try to use the user configuration if present.\e[0m"
		fi
		;;
		i ) if echo $OPTARG | grep -Poq '\d+'; then
			INTERVAL=$OPTARG
		else
			echo -e "\e[1;33m - WARNING: option -i requires an argument\e[0m"
			INTERVAL=10
		fi
		;;
		g ) if echo $OPTARG | grep -Eq '^[+]?[0-9]+$'; then
			GAIN=$OPTARG
		elif echo $OPTARG | grep -Eq '^-[0-9]+$'; then
			GAIN=$OPTARG
		else
			echo -e "\e[1;33m - WARNING: option -g requires an argument\e[0m"
			GAIN=-50
		fi
		;;
		n ) STEP=servercheck
		;;
		o ) BELL=OFF
		;;
		h ) STEP=givemehelp
		;;
		*) INVALID=1; echo -e "\e[1;31m## ERROR: invalid option $OPTARG\e[0m"
	esac
done

if echo $INVALID | grep -xq "1"; then
	givemehelp
elif echo $STEP | grep -xq "givemehelp"; then
	givemehelp
elif echo $STEP | grep -xq "servercheck"; then
	initialize
else
	STEP=mountscheck; initialize
fi
