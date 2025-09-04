#!/bin/bash

# Ensure /tmp exists and has the proper permissions before
# checking for security updates
# https://github.com/digitalocean/marketplace-partners/issues/94
if [[ ! -d /tmp ]]; then
  mkdir /tmp
fi
chmod 1777 /tmp

apt-get -y update
apt-get -y upgrade
rm -rf /tmp/* /var/tmp/*
history -c
cat /dev/null > /root/.bash_history
unset HISTFILE
apt-get -y autoremove
apt-get -y autoclean
find /var/log -mtime -1 -type f -exec truncate -s 0 {} \;
rm -rf /var/log/*.gz /var/log/*.[0-9] /var/log/*-????????
rm -rf /var/lib/cloud/instances/*
rm -f /root/.ssh/authorized_keys /etc/ssh/*key*
touch /etc/ssh/revoked_keys
chmod 600 /etc/ssh/revoked_keys

# Securely erase the unused portion of the filesystem
GREEN='\033[0;32m'
NC='\033[0m'
printf "\n${GREEN}Writing zeros to the remaining disk space to securely
erase the unused portion of the file system.
Depending on your disk size this may take several minutes.
The secure erase will complete successfully when you see:${NC}
    writing to '/zerofile': No space left on device\n
"

if [[ ! -v IMMICH_TEST_PROD_BRANCH ]]; then 
    # Time between tests.
    IMMICH_TEST_PROD_BRANCH="main"
fi

# Get branch
IMMICH_BRANCH_REF_NAME=$(cat /opt/immich/branch.txt | tr -d '\n')

if [[ "$IMMICH_BRANCH_REF_NAME" == "" ]]; then 
    IMMICH_BRANCH_REF_NAME="main"
fi

echo "on branch $IMMICH_TEST_PROD_BRANCH"

if [ "$IMMICH_BRANCH_REF_NAME" == "$IMMICH_TEST_PROD_BRANCH" ]; then
  printf "\n${GREEN} Erasing with dd"
  dd if=/dev/zero of=/zerofile
else
  printf "\n${GREEN} Erasing with fallocate"
  fallocate -l 10G /zerofile
fi

sync; rm /zerofile; sync
cat /dev/null > /var/log/lastlog; cat /dev/null > /var/log/wtmp
sudo apt-get --yes purge droplet-agent*

