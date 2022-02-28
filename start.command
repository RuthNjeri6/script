#!/bin/sh
cd -- "$(dirname "$BASH_SOURCE")"
export PATH=/usr/bin:/bin:$PATH
export $(grep -v '^#' .env | xargs)
echo "${DJANGO_SECRET_KEY} ${MONGODB_URI}"
exit 1
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'
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
docker-compose up -d --force-recreate 2>> log/start_errors.txt
status=$?
if test $status -eq 0 ; then
    echo "${GREEN}Starting up the application...${NC}"
    sleep 30
    open http://localhost
else
    echo "${RED}An error occured while installing the software!!!. Please contact the adminstrator to report the problem.${NC}"
    exit 1
fi