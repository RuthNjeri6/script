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

    # check for existing containers and remove them
    if docker container inspect biomarker-data >/dev/null 2>&1; then
            docker stop biomarker-data 2>> ./log/get_data_errors.txt
            docker rm biomarker-data 2>> ./log/get_data_errors.txt
    fi
    # check and remove existing data directory
    WORKING_DIR="./biomarker-data" 2>> ./log/get_data_errors.txt
    if [ -d "$WORKING_DIR" ];
        then rm -Rf $WORKING_DIR; 2>> ./log/get_data_errors.txt
    fi
    # Load image from tar file and run container using the image
    docker load --input metrica-data-image.tar.gz 2>> ./log/get_data_errors.txt
    docker run --name=biomarker-data --env-file ./.env  -v /var/run/docker.sock:/var/run/docker.sock --network=bm metrica-data-image:latest 2>> ./log/get_data_errors.txt
    docker cp biomarker-data:/home/app/data/investigators ./biomarker-data 2>> ./log/get_data_errors.txt

    docker rm  -v --force biomarker-data 2>> ./log/get_data_errors.txt
    NOW=$( date '+%F_%H:%M:%S' ) 2>> ./log/get_data_errors.txt
    FILE="${NOW}.dmg" 2>> ./log/get_data_errors.txt
    echo "${BLUE}" 2>> ./log/get_data_errors.txt
    hdiutil create  "$FILE" -encryption -srcfolder ./biomarker-data 2>> ./log/get_data_errors.txt
    echo "${NC}" 2>> ./log/get_data_errors.txt

    rm -r ./biomarker-data 2>> ./log/get_data_errors.txt 

    # wait for sometime then notify the user that the software is updated.
    sleep 15
    echo "${GREEN}Data retrieved successfully!!! Go to the ${FILE} folder to access the data.${NC}" 2>> ./log/get_data_errors.txt