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
    sleep 1
    done
    fi
    # if [ -x "$(command -v aws)" ]; then
    #     echo "You already have aws cli...Good to go!"
    # else
    #     echo "Installing awscli..."
    #     brew install awscli
    #     echo "Please Enter your aws credentials and press Return (Warning: if you dont have the credentials press Control + C to cancel )...."
    #     aws configure
    # fi
    # echo "coping audio files...."
    # docker cp -a vocal:/home/app/webapp/media/audios/. ./container_data/audios
    # docker cp -a social:/home/app/webapp/social/media/videos/. ./container_data/videos
    # docker cp social:/home/app/webapp/social/data.csv ./container_data/social/data.csv
    # docker cp global:/home/app/webapp/social/data.csv ./container_data/global/data.csv
    # echo "Done coping audio files...."

    docker run --rm  -v ~/.aws:/root/.aws amazon/aws-cli ecr get-login-password \
        --region eu-central-1 \
    | docker login \
        --username AWS \
        --password-stdin 715941344009.dkr.ecr.eu-central-1.amazonaws.com

    docker-compose down 
    biomarkers-local_static_volume biomarkers-local_social_static_volume biomarkers-local_global_static_volume
    docker-compose pull
    docker-compose up --force-recreate -d --remove-orphans 
