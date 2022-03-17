#!/bin/sh

# exit when any command fails
set -e

# define echo text color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# echo an error message before exiting with a status not equal to 0
trap '[[ $? -ne 0 ]] && echo  "${RED}An error occurred while getting data from the software!!!. Please contact the Administrator to report the problem.${NC}"' EXIT

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
    # docker run --rm  -v ~/.aws:/root/.aws amazon/aws-cli ecr get-login-password \
    #     --region eu-central-1 \
    # | docker login \
    #     --username AWS \
    #     --password-stdin 715941344009.dkr.ecr.eu-central-1.amazonaws.com 2>> ../log/get_data_errors.txt

    # aws_status=$?
    # if test $aws_status -ne 0 ; then
    #     exit 1
    # fi

    # create volume
    # containers="$(docker container ls -aq)" 
    # if [ ${#containers[@]} -ne 0 ]; then
    #     for container in ${containers[@]}; do
    #         echo $container
    #     done
    # fi
    if docker container inspect biomarker-data >/dev/null 2>&1; then
            echo "container exists"
            docker stop biomarker-data
            docker rm biomarker-data
    else
        echo "container does not exit"
    fi
    docker volume create data-vol
    # docker run -d --name=biomarker-data  -v data-vol:/home/app/data 715941344009.dkr.ecr.eu-central-1.amazonaws.com/biomarker-data-model:latest
    docker run --name=biomarker-data  -v data-vol:/home/app/data -v /var/run/docker.sock:/var/run/docker.sock -v /Users/ruthnjeri/work/biomarker-data-model://home/app/ --network=bm data-model
    docker cp biomarker-data:/home/app/data/investigators ./

    # docker rm  -v --force biomarker-data

    # wait for sometime then notify the user that the software is updated.
    sleep 30
    echo "${GREEN}Data retrieved from Software successfully!!! Go to the biomarker-data.zip folder to access the data.${NC}"