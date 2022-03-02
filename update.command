#!/bin/sh

# exit when any command fails
set -e

# define echo text coloe variables
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# echo an error message before exiting with a status not equal to 0
trap '[[ $? -ne 0 ]] && echo  "${RED}An error occurred while installing the software!!!. Please contact the Administrator to report the problem.${NC}"' EXIT

# navigate to the working directory
cd -- "$(dirname "$BASH_SOURCE")"

# open docker if its not open
    if (! docker stats --no-stream ); then
    # On Mac OS this would be the terminal command to launch Docker
    open -a Docker
    #Wait until Docker daemon is running and has completed initialisation
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
        --password-stdin 715941344009.dkr.ecr.eu-central-1.amazonaws.com 2>> log/update_errors.txt

    aws_status=$?
    if test $aws_status -ne 0 ; then
        exit 1
    fi

    # stop all the running containers
    docker-compose --project-name biomarker-offline down  2>> log/update_errors.txt
    down_status=$?
    if test $down_status -ne 0; then
        exit 1
    fi

    # remove the static volumes from the stoped containers
    docker volume rm biomarker-offline_cockpit_static_volume biomarker-offline_static_volume biomarker-offline_social_static_volume biomarker-offline_global_static_volume biomarker-offline_aq_static_volume biomarker-offline_gaze_static_volume 2>> log/update_errors.txt
    rm_status=$?
    if test $rm_status -ne 0; then
        exit 1
    fi

    # pull the latest images 
    docker-compose --project-name biomarker-offline pull 2>> log/update_errors.txt
    pull_status=$?
    if test $pull_status -ne 0; then
        exit 1
    fi

    # run the containerners with the latest images
    docker-compose --project-name biomarker-offline up --force-recreate -d 2>> log/update_errors.txt
    up_status=$?
    if test $up_status -ne 0; then
        exit 1
    fi

    # wait for sometime then notify the user that the software is updated.
    sleep 30
    echo "${GREEN}Software Updated successfully!!!. Start the Application by opening the start.command file.${NC}"