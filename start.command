#!/bin/sh

# exit when any command fails
set -e

# define variables for echo test color
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# echo an error message before exiting
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

# spin up the containers(most will be up to date) and open the application on the browser
docker-compose -f docker-compose-mongo.yaml up -d --force-recreate 2>> log/start_errors.txt
docker-compose --project-name biomarker-offline up -d --force-recreate 2>> log/start_errors.txt
status=$?
if test $status -eq 0 ; then
    echo "${GREEN}Starting up the application...${NC}"
    /usr/bin/osascript -e "tell application \"Google Chrome\" to if number of windows > 0 then quit" -e "delay 30" 2>> log/start_errors.txt
    /usr/bin/osascript -e "tell application \"Google Chrome\"" -e "activate" -e "delay 0.5" -e "if not (exists window 1) then reopen" -e "set URL of active tab of window 1 to \"http://localhost\"" -e "tell application \"System Events\"" -e "keystroke \"f\" using {control down, command down}" -e "tell application \"System Events\"" -e "keystroke \"f\" using {shift down, command down}" -e "end tell" -e "tell application \"System Events\"" -e "keystroke \"f\" using {shift down, command down}" -e "end tell" -e "end tell"  -e "end tell" 2>> log/start_errors.txt
else
    exit 1
fi