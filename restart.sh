#!/bin/bash
#
# Takes down the existing composed Docker images and brings them back up, rebuilding them
# Mostly used during development after making changes to the Dockerfile
#

docker-compose down
docker-compose up --build
