#!/bin/bash

set -e

PATCH_LEVEL=033

docker build -t appliedolap/essbase:11.1.2.4.$PATCH_LEVEL -t appliedolap/essbase:latest --build-arg PATCH_LEVEL=$PATCH_LEVEL .
docker push appliedolap/essbase:11.1.2.4.$PATCH_LEVEL
docker push appliedolap/essbase:latest
