#!/bin/bash

cd $HOME

# Get branch
IMMICH_BRANCH_REF_NAME=$(cat /opt/immich/branch.txt | tr -d '\n')

if [[ "$IMMICH_BRANCH_REF_NAME" == "" ]]; then 
    IMMICH_BRANCH_REF_NAME="main"
fi

echo "Installing immich in $HOME from branch $IMMICH_BRANCH_REF_NAME"

if [ $(cat $HOME/.bashrc | grep "docker.sock" | wc -l) -eq 0 ]; then
    echo "Adding docker.sock to .bashrc"
    echo "export DOCKER_HOST=unix:///run/user/$(id -u $USER)/docker.sock" >> $HOME/.bashrc
    echo "export XDG_RUNTIME_DIR=/run/user/$(id -u $USER)" >> $HOME/.bashrc
    echo "export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u $USER)/bus" >> $HOME/.bashrc
    echo "export PATH=/usr/bin:/sbin:/usr/sbin:$PATH" >> $HOME/.bashrc
fi

unset DOCKER_HOST


$(cat $HOME/.bashrc | grep XDG_RUNTIME_DIR)
$(cat $HOME/.bashrc | grep PATH)
$(cat $HOME/.bashrc | grep DBUS_SESSION_BUS_ADDRESS)
echo $XDG_RUNTIME_DIR
echo $DBUS_SESSION_BUS_ADDRESS
echo $PATH

systemctl --user daemon-reload

echo "Installing dockerd-rootless-setuptool.sh"
# Install dockerd-rootless-setuptool.sh
HOME=$HOME USER=$USER XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS /usr/bin/dockerd-rootless-setuptool.sh install

$(cat $HOME/.bashrc | grep DOCKER_HOST)

systemctl --user daemon-reload

systemctl --user start docker
systemctl --user enable docker

systemctl --user daemon-reload


## Skip if immich is already running
if [ $(docker ps -q -f name=immich_server) ]; then
    exit 0
fi

# Set install script
curl -o- https://raw.githubusercontent.com/immich-app/immich/$IMMICH_BRANCH_REF_NAME/install.sh > /tmp/install-temp.sh

# if we downlaoded install-temp.sh, then we need to copy it over install.sh
if [ $(cat /opt/immich/install-temp.sh | grep ".env" | wc -l) -gt 0 ]; then
    echo "Copying new install script"
    cp /tmp/install-temp.sh /opt/immich/install.sh
    chmod +x /opt/immich/install.sh
fi


## Ready install immich
cp /opt/immich/install.sh $HOME/install.sh

# Set up caddy
mkdir -p $HOME/immich-app/caddy
cp /opt/immich/Caddyfile $HOME/immich-app/caddy/Caddyfile
cp /opt/immich/docker-compose-caddy.yml $HOME/immich-app/docker-compose-caddy.yml

# Remove docker compose up, we will do it later
sed -i -e 's/docker compose up/echo/g' $HOME/install.sh

# Run install script
/bin/bash -c "cd $HOME ; ./install.sh"

# Fix caddy
/opt/immich/add-caddy.sh $HOME

cd $HOME/immich-app/

# Make sure immich is down
docker compose down

# Set up db location outside of the /immich-app directoy.
sed -i -e "s|DB_DATA_LOCATION=.*|DB_DATA_LOCATION=$HOME\/immich-db\/postgres|g" $HOME/immich-app/.env

mkdir -p $HOME/immich-db/

# Set update script
curl -o- https://raw.githubusercontent.com/immich-app/one-click/refs/heads/$IMMICH_BRANCH_REF_NAME/generic/files/opt/immich/update-immich.sh  > /tmp/update-immich-temp.sh

if [ $(grep 'docker-compose.yml' /tmp/update-immich-temp.sh | wc -l) -gt 0 ]; then
   echo "Using new update script."
   cp /tmp/update-immich-temp.sh /opt/immich/update-immich.sh
   chmod +x /opt/immich/update-immich.sh
fi 

# Check for update and run
/opt/immich/update-immich.sh $1


# start immich
docker compose up --remove-orphans -d --quiet-pull

echo "Finished immich init"
