#!/bin/bash

# THIS SCRIPT BUILDS THE FRONT AND BACKEND AND COPIES THE FILES TO THE DEPLOY FOLDER. 
# IT CAN THEN BE UPLOADED TO GITHUB.

# check for url and port arguments
if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    echo "Usage: ./deploy.sh <url> <port>"
    exit 1
fi
# check for url argument
if [ -z "$1" ]
  then
    echo "No url supplied for pocketbase server"
    echo "Usage: ./deploy.sh <url> <port>"
    exit 1
fi

# check for port argument
if [ -z "$2" ]
  then
    echo "No port supplied for pocketbase server"
    echo "Usage: ./deploy.sh <url> <port>"
    exit 1
fi


cd backend_build
./pb_build.sh

cd ../frontend

# write "import PocketBase from 'pocketbase'; export const pb = new PocketBase('[url][port]');"
# into src/lib/pocketbase.ts
echo "import PocketBase from 'pocketbase'; export const pb = new PocketBase('$1:$2');" > src/lib/pocketbase.ts

npm install
npm run build

cd ../

rm -rf to_deploy
mkdir -p to_deploy
cp pocketbase to_deploy/
cp nginx.conf to_deploy/
cp pb_schema.json to_deploy/
cp deploy.sh to_deploy/
chmod +x to_deploy/deploy.sh
mkdir -p to_deploy/frontend
cp -r frontend/dist to_deploy/frontend
# if 3rd argument is "y" copy pb_data folder to deploy
if [ "$3" = "y" ]
  then
    cp -r pb_data to_deploy/
fi