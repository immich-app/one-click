#!/bin/bash

if [ $(ls -l | grep "docker-compose.yml" | wc -l) -eq 0 ]; then
    echo "Unable to run update-immich.sh"
    echo "docker-compose.yml not found, script should be ran from immich-app directory"
    echo "Possible directories:"
    echo $(find / -name 'docker-compose.yml' 2>/dev/null | grep immich-app | sed 's|docker-compose.yml||')
    echo "Change to the correct directory (cd <directory>), then run the script again"
    exit 1
fi

# Get the current version
curl https://github.com/immich-app/immich/releases/latest  -s -L -I -o /dev/null -w '%{url_effective}' | sed 's|.*\/releases\/tag\/||g' > /opt/immich/current-version.txt
chmod 775 /opt/immich/current-version.txt

touch /opt/immich/installed-version.txt

IMMICH_UPDATE_SKIP=0

if [[ "$(cat /opt/immich/current-version.txt)" == "$(cat /opt/immich/installed-version.txt)" ]]; then
    echo "No new version found, skipping update"
    IMMICH_UPDATE_SKIP=1
fi

if [ $IMMICH_UPDATE_SKIP -eq 0 ]; then
   docker compose down
   curl -fsSL https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml -o docker-compose.yml
   /opt/immich/add-caddy.sh "$PWD/.."
   docker compose pull --policy always --quiet
   if [ "$1" = "skip-run" ]; then 
      echo "Skipping immich run after update"
    else
    # Start immich
       docker compose up --remove-orphans -d --quiet-pull
    fi
   cp /opt/immich/current-version.txt /opt/immich/installed-version.txt
fi
