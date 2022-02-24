#!/bin/sh
cd -- "$(dirname "$BASH_SOURCE")"
export PATH=/usr/bin:/bin:$PATH
# open docker if its not open
if (! docker stats --no-stream ); then
    # On Mac OS this would be the terminal command to launch Docker
    open -a Docker
    #Wait until Docker daemon is running and has completed initialisation
    while (! docker stats --no-stream ); do
    # Docker takes a few seconds to initialize
    echo "Waiting for Docker to launch..."
    sleep 30
    done
fi
# echo "coping audio files...."
# docker cp -a vocal:/home/app/webapp/media/audios/. ./container_data/audios
# echo "Done coping audio files...."
docker-compose up -d
open http://localhost
