#!/bin/sh
cd -- "$(dirname "$BASH_SOURCE")"

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
    
    docker run --rm  -v ~/.aws:/root/.aws amazon/aws-cli ecr get-login-password \
        --region eu-central-1 \
    | docker login \
        --username AWS \
        --password-stdin 715941344009.dkr.ecr.eu-central-1.amazonaws.com

    docker-compose down 
    docker volume rm biomarkers-offline_cockpit_static_volume biomarkers-offline_static_volume biomarkers-offline_social_static_volume biomarkers-offline_global_static_volume biomarkers-offline_aq_static_volume biomarkers-offline_gaze_static_volume
    docker-compose pull
    docker-compose up --force-recreate -d --remove-orphans




