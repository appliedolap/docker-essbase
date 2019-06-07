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

# By default this file supplies a build argument for the PATCH_LEVEL parameter. To use this
# properly you must have the corresponding patch files located in ./patches/NNN (such as
# ./patches/031 and named properly (i.e., the file files from Oracle prepended with 01-, 02-, 
# so on). To skip applying any patches you can specify level 000 or omit the parameter

docker-compose down
docker-compose build --build-arg PATCH_LEVEL=033
docker-compose up --detach
docker-compose logs --follow essbase
