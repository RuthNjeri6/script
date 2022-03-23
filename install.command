#!/bin/sh
# exit when any command fails
set -e
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'
YELLOW='\033[1;33m'

# echo an error message before exiting with a status not equal to 0
trap '[[ $? -ne 0 ]] && echo  "${RED}An error occurred while installing the software!!!. Please contact the Administrator to report the problem.${NC}"' EXIT

# navigate to file directory
cd -- "$(dirname "$BASH_SOURCE")"

# make the other scripts executable(updte.command, start.command, get-data.command)
files=("update.command" "start.command" "./get-data.command")
for file in ${files[@]}; do
    if [[ -x "$file" ]]
    then
        :
    else
        chmod +x $file 2>> log/install_errors.txt
    fi
done

# hide files with sentitive data
hidden_files=("env" "mongo-init.js")
for hidden_file in ${hidden_files[@]}
do
    if [[ -f "$hidden_file" ]]
    then
        mv $hidden_file .$hidden_file 2>> log/install_errors.txt
    fi
done

# get environment variables to be used in data setup on the mongo container
export PATH=/usr/bin:/bin:$PATH
export $(grep -v '^#' .env | xargs)

# function to dump and restore database
setupMongo (){
    docker exec mongo mongodump --archive=dump.db.gz --gzip --uri=${MONGO_CLOUD_URI} 2>> log/install_errors.txt
    mongodump_status=$?
    if test $mongodump_status -ne 0 ; then
        exit 1
    fi
    docker exec mongo mongorestore --archive=dump.db.gz --gzip -v --nsExclude='aq.*responses' --nsExclude='aq.participants' questionnaire -u ${DB_USERNAME} -p ${DB_PASSWORD} --noIndexRestore 2>> log/install_errors.txt
    mongorestore_status=$?
    if test $mongorestore_status -ne 0 ; then
        exit 1
    fi
    docker exec mongo mongo mongo:27017/admin /docker-entrypoint-initdb.d/mongo-init.js -u ${DB_USERNAME} -p ${DB_PASSWORD} 2>> log/install_errors.txt
    mongoinit_status=$?
    if test $mongoinit_status -ne 0 ; then
        exit 1
    fi
    docker exec mongo mongo mongo:27017/aq --eval 'db.investigators.remove({"admin": { "$exists": false } })' -u ${DB_USERNAME} -p ${DB_PASSWORD} --authenticationDatabase ${DB_USERNAME} 2>> log/install_errors.txt
    mongocleanup_status=$?
    if test $mongocleanup_status -ne 0 ; then
        exit 1
    fi
}

# function to spin up the containers
spinUp (){
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
    if [ -x "$(command -v aws)" ]; then
        echo "${BLUE}You already have aws cli...Good to go!${NC}"
    else
        echo "${BLUE}Installing awscli...${NC}"
        brew install awscli
        echo "${BLUE}Please Enter your aws credentials and press Return (Warning: if you dont have the credentials press Control + C to cancel )....${NC}"
        aws configure
    fi
    
    # list all the containers on the host machine
    containers="$(docker container ls -aq)" 2>> log/install_errors.txt

    # remove all existing containers
    if [ ${#containers[@]} -ne 0 ]; then
        # Confirm Installation
        echo "${YELLOW} Reinstalling will delete your currect data. Do you wish to Reinstall this Software? Please answer 1 for yes or 2 for no."
        select yn in "Yes" "No"; do
            case $yn in
                Yes ) break;;
                No ) echo "${NC}"; exit;;
            esac
        done
        echo "${NC}"
        for container in ${containers[@]}; do
            echo $container
            docker container stop $container && docker system prune -af --volumes 2>> log/install_errors.txt
        done
    fi

    # run aws docker image and login to ecr
    docker run --rm  -v ~/.aws:/root/.aws amazon/aws-cli ecr get-login-password \
        --region eu-central-1 \
    | docker login \
        --username AWS \
        --password-stdin 715941344009.dkr.ecr.eu-central-1.amazonaws.com 2>> log/install_errors.txt

    aws_status=$?
    if test $aws_status -ne 0 ; then
        exit 1
    fi

    # run the mongo db container 
    docker-compose -f docker-compose-mongo.yaml  up -d --force-recreate 2>> log/install_errors.txt
    create_mongo_status=$?
    if test $create_mongo_status -ne 0 ; then
        exit 1
    fi

    # add data to mongo db 
    setupMongo
    data_status=$?
    if test $data_status -eq 0 ; then
        echo "${BLUE}Database SetUp completed...${NC}"
    else
        exit 1
    fi

    # run the other containers i.e all the biomarkers, the backend and nginx
    docker-compose --project-name biomarker-offline up -d --force-recreate 2>> log/install_errors.txt
    install_status=$?
    if test $install_status -eq 0; then
        sleep 30
        echo "${GREEN}Software Installed successfully!!!. Start the Application by opening the start.command file.${NC}"
    else
        exit 1
    fi
}

# check if docker is installed

if [ -x "$(command -v docker)" ]; then
    echo "${BLUE}You already have docker...Good to go!${NC}"
else
    echo "Installing docker...."
    if ! command -v brew &>/dev/null; then
    
        git config --global --unset http.proxy 
        git config --global --unset https.proxy
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"

        # if ! grep -qs "recommended by brew doctor" ~/.zshrc; then
        #     echo "Put Homebrew location earlier in PATH ..."
        #     export PATH="/usr/local/bin:$PATH"
        # fi
    else
        echo "${BLUE}You already have Homebrew installed...good job!${NC}"
    fi

    brew install --cask docker

    softwareupdate --install-rosetta
fi
# calling the spinup function
spinUp