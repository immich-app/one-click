#!/bin/sh

# Block all incoming traffic
ufw default deny incoming

# Allow ssh, http, https
ufw allow ssh
ufw allow http
ufw allow https

# Restart ufw
ufw disable
ufw --force enable
