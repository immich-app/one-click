#!/bin/sh


# Add systemd.unified_cgroup_hierarchy=0 to grub
#sed -e 's|GRUB_CMDLINE_LINUX="|GRUB_CMDLINE_LINUX="systemd.unified_cgroup_hierarchy=0 |g' \
#    -i /etc/default/grub
#update-grub


# Prerequisites for rootless docker
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y curl dbus-user-session
sudo apt-get install -y uidmap systemd-container
sudo apt-get install -y docker-ce-rootless-extras

# Place for global immich scripts
mkdir -p /opt/immich/

# Temp place for immich app
mkdir -p $HOME/immich-app/caddy

# Set version
echo "${application_version}" > /opt/immich/version.txt
chmod 755 /opt/immich/version.txt

# Set install script
curl -o- https://raw.githubusercontent.com/immich-app/immich/main/install.sh > /opt/immich/install-temp.sh

# if we downlaoded install-temp.sh, then we need to copy it over install.sh
if [ $(cat /opt/immich/install-temp.sh | grep ".env" | wc -l) -gt 0 ]; then
    cp /opt/immich/install-temp.sh /opt/immich/install.sh
fi

chmod +x /opt/immich/install.sh

chmod +x /opt/immich/add-caddy.sh


# Need a copy of Caddyfile for the docker compose pull
cp /opt/immich/Caddyfile $HOME/immich-app/caddy/Caddyfile

## Ready pre-install immich
cp /opt/immich/install.sh $HOME/install.sh
mkdir -p $HOME/immich-app/caddy
cp /opt/immich/docker-compose-caddy.yml $HOME/immich-app/docker-compose-caddy.yml

# Remove docker compose up, we will do it later
sed -i 's/docker compose up/echo/g' $HOME/install.sh

# Run install script for pre-install
/bin/bash -c "cd $HOME ; ./install.sh"

# Fix caddy
/opt/immich/add-caddy.sh "$HOME"

#  Collect images
#cd $HOME/immich-app/ ; 
#docker compose pull --policy always;

# Remove install files from root user.
cd $HOME/immich-app/ ; 
docker compose down
cd $HOME ; rm -rf immich-app ; rm install.sh ;

# Create immich user
adduser immich --disabled-password --gecos GECOS
usermod -aG docker immich


chmod +x /opt/immich/init.sh
chmod +x /opt/immich/update-immich.sh
chmod +x /opt/immich/move-immich.sh

# Set port 80 access for startup
echo 'net.ipv4.ip_unprivileged_port_start=80' >> '/etc/sysctl.conf'
echo 'net.ipv4.ip_unprivileged_port_start=80' > '/usr/lib/sysctl.d/80-set-http-unpriv.conf'


# Remove the docker service so we can run docker rootless
sudo systemctl stop docker.service docker.socket
sudo systemctl disable --now docker.service docker.socket

sudo rm /var/run/docker.sock

chown -R immich:immich /opt/immich/

mkdir -p /home/immich/.config/docker/ ; echo '{"exec-opts": ["native.cgroupdriver=cgroupfs"]}' > /home/immich/.config/docker/daemon.json

chown -R immich:immich /home/immich/.config/docker

/bin/su -l -s "/bin/bash" -c 'echo "immich user setup"' immich

if [ $(cat /home/immich/.bashrc | grep "docker.sock" | wc -l) -eq 0 ]; then
    echo "Adding docker.sock to .bashrc"
    echo "export DOCKER_HOST=unix:///run/user/$(id -u immich)/docker.sock" >> /home/immich/.bashrc
    echo "export XDG_RUNTIME_DIR=/run/user/$(id -u immich)" >> /home/immich/.bashrc
    echo "export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u immich)/bus" >> /home/immich/.bashrc
    echo 'export PATH=/usr/bin:/sbin:/usr/sbin:$PATH' >> /home/immich/.bashrc
    chown immich:immich /home/immich/.bashrc
fi

sudo loginctl enable-linger root

# start systemd for immich user
sudo systemctl start user@$(id -u immich).service

# Set up immich as the immich user so that we have a clean ready environment.
sudo loginctl enable-linger immich

mkdir -p /home/immich/.config/systemd

chown -R immich:immich /home/immich/.config/

# Set up immich as the immich user so that we have a clean ready environment.
/bin/su -l -s "/bin/bash" -c 'cd /home/immich ; HOME=/home/immich USER=immich PATH=/usr/bin:/sbin:/usr/sbin:$PATH /opt/immich/init.sh skip-run' immich

echo "immich init done"

# Shut down the immich build.

/bin/su -l -s "/bin/bash" -c 'cd /home/immich/immich-app ; docker compose down ; echo immich-init-shutdown-done' immich

# set loginctl to enable-linger immich after rootless docker is setup.
sudo loginctl enable-linger immich

# Remove immich-app and immich-db directories, these will be made on first user run.

rm -rf /home/immich/immich-app/
rm -rf /home/immich/immich-db/

mkdir -p /var/lib/digitalocean/

echo "immich snapshot install done."


