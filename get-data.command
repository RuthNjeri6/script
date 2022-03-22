#!/bin/sh

# exit when any command fails
set -e

# define echo text color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# echo an error message before exiting with a status not equal to 0
trap '[[ $? -ne 0 ]] && echo  "${RED}An error occurred while retrieving!!!. Please contact the Administrator to report the problem.${NC}"' EXIT

# navigate to the working directory
cd -- "$(dirname "$BASH_SOURCE")"

# open docker if its not open
    if (! docker stats --no-stream ); then
    # On Mac OS this would be the terminal command to launch Docker
    open -a Docker
    #Wait until Docker daemon is running and has completed Initialisation
    while (! docker stats --no-stream ); do
    # Docker takes a few seconds to initialize
    echo "${BLUE}Waiting for Docker to launch...${NC}"
    sleep 30
    done
    fi
    
    # run aws docker image and login to ecr
    docker run --rm  -v ~/.aws:/root/.aws amazon/aws-cli ecr get-login-password \
        --region eu-central-1 \
    | docker login \
        --username AWS \
        --password-stdin 715941344009.dkr.ecr.eu-central-1.amazonaws.com 2>> ./log/get_data_errors.txt

    aws_status=$?
    if test $aws_status -ne 0 ; then
        exit 1
    fi

    # check for existing containers and remove them
    if docker container inspect biomarker-data >/dev/null 2>&1; then
            docker stop biomarker-data 2>> ./log/get_data_errors.txt
            docker rm biomarker-data 2>> ./log/get_data_errors.txt
    fi
    # create volume
    docker volume create data-vol 2>> ./log/get_data_errors
    docker pull 715941344009.dkr.ecr.eu-central-1.amazonaws.com/biomarker-data-model:latest 2>> ./log/get_data_errors.txt
    docker run --name=biomarker-data --env-file ./.env  -v data-vol:/home/app/data -v /var/run/docker.sock:/var/run/docker.sock --network=bm 715941344009.dkr.ecr.eu-central-1.amazonaws.com/biomarker-data-model:latest
    # docker run --name=biomarker-data --env-file ./.env  -v data-vol:/home/app/data -v /var/run/docker.sock:/var/run/docker.sock -v /Users/ruthnjeri/work/biomarker-data-model://home/app/ --network=bm data-model
    docker cp biomarker-data:/home/app/data/investigators ./biomarker-data 2>> ./log/get_data_errors.txt

    docker rm  -v --force biomarker-data 2>> ./log/get_data_errors.txt

    # wait for sometime then notify the user that the software is updated.
    sleep 30
    echo "${GREEN}Data retrieved successfully!!! Go to the biomarker-data folder to access the data.${NC}"