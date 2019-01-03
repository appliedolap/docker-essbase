#!/bin/bash
#
# Run from the folder containing the compose file and use to quickly monitor/
# follow the logs from just the Essbase server

docker-compose logs --follow essbase
