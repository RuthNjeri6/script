#!/bin/sh
export PATH=/usr/bin:/bin:$PATH
# open docker if its not open
if (! docker stats --no-stream ); then
    # On Mac OS this would be the terminal command to launch Docker
    open -a Docker
    #Wait until Docker daemon is running and has completed initialisation
    while (! docker stats --no-stream ); do
    # Docker takes a few seconds to initialize
    echo "Waiting for Docker to launch..."
    sleep 1
    done
fi
open http://localhost
