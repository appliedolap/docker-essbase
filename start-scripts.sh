#!/bin/bash

for script in start_scripts/*.msh
do
    startMaxl.sh $script
done
