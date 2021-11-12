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

    docker run --rm  -v ~/.aws:/root/.aws amazon/aws-cli ecr get-login-password \
        --region eu-central-1 \
    | docker login \
        --username AWS \
        --password-stdin 715941344009.dkr.ecr.eu-central-1.amazonaws.com
    
    docker-compose down
    docker-compose pull
    echo "done Pulling images"
    docker-compose up -d --remove-orphans