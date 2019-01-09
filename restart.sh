#!/bin/bash
#
# Takes down the existing composed Docker images and brings them back up, rebuilding them
# Mostly used during development after making changes to the Dockerfile
# 
# The command is run in detached mode, you can follow the logs by using the normal Docker
# Compose logs commands or using the follow-essbase-logs.sh example/script in this folder
#
# DO NOT RUN THIS IF YOU HAVE CUBES/DATA ON YOUR CONTAINER THAT YOU WANT TO SAVE, AS THEY
# WILL BE LOST!

docker-compose down
docker-compose up --build --detach
