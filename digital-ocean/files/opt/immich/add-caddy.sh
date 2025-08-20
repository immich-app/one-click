IMMICH_LOCATION="$1"

if [ "$IMMICH_LOCATION" = "" ]; then
    IMMICH_LOCATION="$PWD"
fi

if [ $(ls -l "$IMMICH_LOCATION" | grep "immich-app" | wc -l) -eq 0 ]; then
    echo "Unable to run add-caddy.sh"
    echo "immich-app directory not found, script should be ran from immich-app directory"
    echo "Possible directories:"
    echo $(find / -name 'immich-app' 2>/dev/null)
    echo "Change to the correct parent directory (cd <immich-appdirectory>/..), then run the script again"
    exit 1
fi


if [ $(ls -l "$IMMICH_LOCATION/immich-app" | grep "docker-compose.yml" | wc -l) -eq 0 ]; then
    echo "Unable to run add-caddy.sh"
    echo "docker-compose.yml not found, script should be ran from immich-app parent directory"
    echo "Possible directories:"
    echo $(find / -name 'docker-compose.yml' 2>/dev/null | grep immich-app)
    echo "Change to the correct directory (cd <directory>/..), then run the script again"
    exit 1
fi


cp /opt/immich/docker-compose-caddy.yml "$IMMICH_LOCATION/immich-app/docker-compose-caddy.yml"

if [ $(cat "$IMMICH_LOCATION/immich-app/docker-compose.yml" | grep "docker-compose-caddy.yml" | wc -l) -gt 0 ]; then
    echo "Caddy is already defined in docker-compose.yml"
else
    mv "$IMMICH_LOCATION/immich-app/docker-compose.yml" "$IMMICH_LOCATION/immich-app/docker-compose.yml.bak"
    { echo -e "include:\n - docker-compose-caddy.yml\n" ; cat "$IMMICH_LOCATION/immich-app/docker-compose.yml.bak" ; } > "$IMMICH_LOCATION/immich-app/docker-compose.yml" ; 
    sed -i -e 's/-e include/include/' "$IMMICH_LOCATION/immich-app/docker-compose.yml"
fi