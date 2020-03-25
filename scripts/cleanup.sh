#!/bin/bash -eu

SSH_USER=${SSH_USERNAME:-jarvis}
date > /etc/vagrant_box_build_date

# Modify /etc/fstab to mount /tmp with noexec
# preseed.cfg settings are not being honored

sed -i.bak -r -e '/\s+\/tmp\s+/ { /noexec/! s%\s+/tmp\s+(\S+)\s+% /tmp \1 noexec,%; }' /etc/fstab

# Stop services for cleanup
service rsyslog stop

# Append date built to MOTD and remove the crap
MOTD_FILE=/etc/motd
BANNER_WIDTH=64
PLATFORM_RELEASE=$(lsb_release -sd)
PLATFORM_MSG=$(printf '%s' "$PLATFORM_RELEASE")
BUILT_MSG=$(printf 'built %s' $(date +%Y-%m-%d))
printf '%0.1s' "-"{1..64} > ${MOTD_FILE}
printf '\n' >> ${MOTD_FILE}
printf '%2s%-30s%30s\n' " " "${PLATFORM_MSG}" "${BUILT_MSG}" >> ${MOTD_FILE}
printf '%0.1s' "-"{1..64} >> ${MOTD_FILE}
printf '\n' >> ${MOTD_FILE}
chmod -x /etc/update-motd.d/80-livepatch 
chmod -x /etc/update-motd.d/10-help-text
chmod -x /etc/update-motd.d/50-motd-news 

# Reduce installed languages to just "en_US"
sed -i '/^[^# ]/s/^/# /' /etc/locale.gen
LANG=en_US.UTF-8
LC_ALL=$LANG
locale-gen --purge $LANG
update-locale LANG=$LANG LC_ALL=$LC_ALL

# Remove some packages to get a minimal install
dpkg --list 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' | xargs apt-get -y purge
dpkg --list | awk '{print $2}' | grep linux-source | xargs apt-get -y purge
dpkg --list | awk '{print $2}' | grep -- '-doc$' | xargs apt-get -y purge
apt remove -y ppp pppconfig pppoeconf cpp gcc g++ libx11-data xauth libxmuu1 libxcb1 libx11-6 libxext6 linux-source language-pack-en language-pack-gnome-en
apt-get -y remove '.*-dev$'

# Disable IPv6
sed -i -e 's/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="ipv6.disable=1"/' /etc/default/grub
        
# Disable root login via ssh
sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config

# Remove grub timeout and splash screen
sed -i -e '/^GRUB_TIMEOUT=/aGRUB_RECORDFAIL_TIMEOUT=0' \
    -e 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet nosplash"/' \
    -e 's/^#GRUB_DISABLE_RECOVERY="true"/GRUB_DISABLE_RECOVERY="true"/' \
    /etc/default/grub
update-grub

# Clear audit logs
if [ -f /var/log/audit/audit.log ]; then
    cat /dev/null > /var/log/audit/audit.log
fi
if [ -f /var/log/wtmp ]; then
    cat /dev/null > /var/log/wtmp
fi
if [ -f /var/log/lastlog ]; then
    cat /dev/null > /var/log/lastlog
fi

# Cleanup persistent udev rules
if [ -f /etc/udev/rules.d/70-persistent-net.rules ]; then
    rm /etc/udev/rules.d/70-persistent-net.rules
fi

# Cleanup /tmp directories
rm -rf /tmp/*
rm -rf /var/tmp/*

#cleanup current ssh keys
rm -f /etc/ssh/ssh_host_*

# Add check for ssh keys on reboot...regenerate if neccessary
cat <<EOL | sudo tee /etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

test -f /etc/ssh/ssh_host_dsa_key || dpkg-reconfigure openssh-server
exit 0
EOL

chmod +x /etc/rc.local

# Reset hostname
cat /dev/null > /etc/hostname

# Cleanup shell history
history -c
history -w

# Truncate logs
find /var/log -type f -exec truncate --size=0 {} \;

# Cleanup apt
apt-get clean
apt autoremove -y
apt update

# Zero out the rest of the free space using dd, then delete the written file.
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

# Add `sync` so Packer doesn't quit too early, before the large file is deleted.
sync

echo "==> Disk usage after cleanup"
df -h