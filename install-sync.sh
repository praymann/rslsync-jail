#!/bin/sh
#
# Install Resilio Sync, set config path. This script can also be run to update
# rslsync.
#
# Revision 170420a-yottabit

configDir=$(dialog --no-lines --stdout --inputbox "Persistent storage is:" 0 0 \
"/config") || exit

if [ -d "$configDir" ] ; then
  echo "$configDir exists, like a boss!"
else
  echo "$configDir does not exist, so exiting (you might want to link a dataset)."
  exit
fi

/usr/sbin/pkg update || exit
/usr/sbin/pkg upgrade --yes || exit
/usr/sbin/pkg install --yes wget || exit
/usr/sbin/pkg clean --yes || exit

echo "Killing rslsync in case it is running."
/usr/bin/killall rslsync
/usr/bin/killall -9 rslsync

/usr/local/bin/wget "https://download-cdn.resilio.com/stable/FreeBSD-x64/resilio-sync_freebsd_x64.tar.gz" \
|| exit
/usr/bin/tar xvzf resilio-sync_freebsd_x64.tar.gz || exit

[ ! -d "$configDir/.sync" ] && mkdir -p "$configDir/.sync"

echo "Checking for $configDir/sync.conf."
if [ ! -f "$configDir/sync.conf" ] ; then
  echo "$configDir/sync.conf does not exist, so creating."
  "$configDir/rslsync" --dump-sample-config > "$configDir/sync.conf" || exit
  sed -i "" -e "s~// \"storage_path\" : \"/home/user/.sync\",~\"storage_path\" : \"$configDir/.sync\"~" \
"$configDir/sync.conf" || exit
else
  echo "$configDir/sync.conf found."
fi

echo "Checking suitability of /etc/rc.local."
[ ! -f "/etc/rc.local" ] && touch "/etc/rc.local" && chmod 755 "/etc/rc.local"

echo "Adding to /etc/rc.local."
echo "\"$configDir/rslsync\" --config \"$configDir/sync.conf\"" \
>> "/etc/rc.local" || exit

echo "Starting /etc/rc.local."
/etc/rc.local