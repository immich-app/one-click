#!/bin/bash
################################################
## Prerequisites
chmod +x /root/vultr-helper.sh
. /root/vultr-helper.sh
error_detect_on

apt update
apt install -y plocate

install_cloud_init latest