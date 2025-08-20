#!/bin/bash

if [ $(whoami) != "root" ]; then
    echo "This script must be run as root"
    exit 1
fi

IMMICH_SOURCE_DIR="$1"
IMMICH_TARGET_DIR="$2"
IMMICH_USER="$3"

IMMICH_USAGE_ERROR="Usage: $0 '<immich-source-dir>' '<immich-target-dir>' '<immich-user>'"

# Check if source and target directories are provided
if [ "$IMMICH_SOURCE_DIR" = "" ]; then
    echo $IMMICH_USAGE_ERROR
    exit 1
fi

if [ "$IMMICH_TARGET_DIR" = "" ]; then
    echo $IMMICH_USAGE_ERROR
    exit 1
fi

# Add trailing slash to directory if not present
if [[ "$IMMICH_SOURCE_DIR" == *'/' ]]; then
    echo "source directory: $IMMICH_SOURCE_DIR"
else
    IMMICH_SOURCE_DIR="$IMMICH_SOURCE_DIR/"
    echo "source directory: $IMMICH_SOURCE_DIR"
fi

if [[ "$IMMICH_TARGET_DIR" == *'/' ]]; then
    echo "target directory: $IMMICH_TARGET_DIR"
else
    IMMICH_TARGET_DIR="$IMMICH_TARGET_DIR/"
    echo "target directory: $IMMICH_TARGET_DIR"
fi

# Check if source and target directories are immich-app directories
if [[ "$IMMICH_SOURCE_DIR" != *"immich-app/" ]]; then
    echo "source directory must be immich-app directory  (should end in /immich-app)"
    echo $IMMICH_USAGE_ERROR
    exit 1
fi

# remove trailing immich-app from target directory if present
if [[ "$IMMICH_TARGET_DIR" == *"immich-app/" ]]; then
    IMMICH_TARGET_DIR="$(echo "$IMMICH_TARGET_DIR" | sed 's|immich-app\/||')"
    IMMICH_TARGET_DIR="$IMMICH_TARGET_DIR/"
fi

# Check if target directory is root
if [[ "$IMMICH_TARGET_DIR" == "/" ]]; then
    echo "target directory must not be root"
    echo "Usage: $0 '<immich-source-dir>' '<immich-target-dir>'"
    exit 1
fi

# Check if source directory has a docker-compose.yml file
if [ $(ls -l  "$IMMICH_SOURCE_DIR" | grep "docker-compose.yml" | wc -l) -eq 0 ]; then
    echo "Unable to run $0"
    echo $IMMICH_USAGE_ERROR
    echo "docker-compose.yml not found in source directory!"
    echo "Possible directories:"
    echo $(find / -name 'docker-compose.yml' 2>/dev/null | grep immich-app | sed 's|docker-compose.yml||')
    exit 1
fi

# Set immich user if not provided
if [ "$IMMICH_USER" = "" ]; then
    read -p "Enter user to run immich(immich): " IMMICH_USER
fi

if [ "$IMMICH_USER" = "" ]; then
    if [ $(cat /etc/passwd | grep -v '/nologin' | grep -v '/shutdown' | grep -v '/halt' | grep immich | wc -l) -eq 0 ]; then
        echo "immich user not found, using root user"
        IMMICH_USER="root"
    else
        echo "setting up for 'immich' user"
        IMMICH_USER="immich"
    fi
fi

if [ $(cat /etc/passwd | grep -v '/nologin' | grep -v '/shutdown' | grep -v '/halt' | grep $IMMICH_USER | wc -l) -eq 0 ]; then
    echo "$IMMICH_USER user not found, please create a user called $IMMICH_USER"
    exit 1
fi


# Work from root directory
cd /

# Create target directory if it doesn't exist
mkdir -p "$IMMICH_TARGET_DIR"

# Check if create target directory was successful
if [ $? -ne 0 ]; then
    echo "failed to create target directory $IMMICH_TARGET_DIR"
    echo $IMMICH_USAGE_ERROR
    exit 1
fi

# Check if target directory is empty
if [ $(ls -1 "$IMMICH_TARGET_DIR/immich-app/" 2>/dev/null | wc -l) -gt 0 ]; then
    echo "target directory $IMMICH_TARGET_DIR/immich-app/ is not empty, please empty it or choose a different target directory"
    exit 1
fi

# Set immich user as owner of target directory
chown -R $IMMICH_USER:$IMMICH_USER "$IMMICH_TARGET_DIR"

# Stop immich
su -s /bin/bash -c "cd $IMMICH_SOURCE_DIR ; docker compose down" $IMMICH_USER

# Move immich-app directory
mv "$IMMICH_SOURCE_DIR" "$IMMICH_TARGET_DIR"

# Check if move was successful
if [ $? -ne 0 ]; then
    echo "failed to move immich-app directory"
    echo $IMMICH_USAGE_ERROR
    exit 1
fi

# Check if docker-compose.yml file is present in target directory
if [ $(ls -l "$IMMICH_TARGET_DIR/immich-app/" | grep "docker-compose.yml" | wc -l) -eq 0 ]; then
    echo "failed to move immich-app directory, docker-compose.yml file is missing"
    echo $IMMICH_USAGE_ERROR
    exit 1
else
    echo "moved immich-app directory successfully"
fi

# Start immich
cd "$IMMICH_TARGET_DIR"/immich-app/ ; su -s /bin/bash -c "cd $IMMICH_TARGET_DIR/immich-app/ ; docker compose up -d" $IMMICH_USER
