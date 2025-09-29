#!/bin/bash

# Immich
# Script to meet the requirments of 99-img-check.sh

echo 'vultr' > /opt/immich/platform.txt
chown -R immich:immich /opt/immich/

cat /dev/null > /var/log/lastlog; cat /dev/null > /var/log/wtmp

# Cleanup log files
cat /dev/null > /var/log/auth.log
cat /dev/null > /var/log/kern.log
cat /dev/null > /var/log/ufw.log
cat /dev/null > /var/log/dpkg.log
