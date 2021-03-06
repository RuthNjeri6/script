#!/bin/sh
# export PATH=/usr/bin:/bin:$PATH
# function to spin up the containers
cd -- "$(dirname "$BASH_SOURCE")"
# make the other scripts executable
chmod +x update.command
chmod +x start.command
mv env .env
mv mongo-init.js .mongo-init.js
spinUp (){
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
    if [ -x "$(command -v aws)" ]; then
        echo "You already have aws cli...Good to go!"
    else
        echo "Installing awscli..."
        brew install awscli
        echo "Please Enter your aws credentials and press Return (Warning: if you dont have the credentials press Control + C to cancel )...."
        aws configure
    fi

    docker run --rm  -v ~/.aws:/root/.aws amazon/aws-cli ecr get-login-password \
        --region eu-central-1 \
    | docker login \
        --username AWS \
        --password-stdin 715941344009.dkr.ecr.eu-central-1.amazonaws.com
    docker-compose up -d --remove-orphans
}

setupMongo (){
    docker exec mongo mongodump --archive=dump.db.gz --gzip --uri="mongodb+srv://tas:tas123@autismus.ypmhk.mongodb.net/aq" && docker exec mongo mongorestore --archive=dump.db.gz --gzip questionnaire -u admin -p 123456 --noIndexRestore  && docker exec mongo mongo mongodb:27017/admin /docker-entrypoint-initdb.d/mongo-init.js -u admin -p 123456
}

# check if docker is installed

if [ -x "$(command -v docker)" ]; then
    echo "You already have docker...Good to go!"
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
        echo "You already have Homebrew installed...good job!"
    fi

    brew install --cask docker

    softwareupdate --install-rosetta
fi

spinUp

setupMongo