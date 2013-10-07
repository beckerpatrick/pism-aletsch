#!/bin/bash

set -x -e

#
python create_altesch.py

# config file
CDLCONFIG=aletsch_config.cdl
PCONFIG=aletsch_config.nc
ncgen -o $PCONFIG $CDLCONFIG
