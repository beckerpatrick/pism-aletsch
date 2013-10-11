#!/bin/bash

set -x -e

srs="epsg:21781"
python create_aletsch.py
nc2cdo.py --srs $srs pism_Aletsch_1880.nc
cmb_file=aletsch_cmb_1865-2008.nc
./grid2nc.py -o $cmb_file
nc2cdo.py --srs $srs $cmb_file
cdo remapbil,$cmb_file pism_Aletsch_1880.nc pism_Aletsch_1880_small.nc
# config file
CDLCONFIG=aletsch_config.cdl
PCONFIG=aletsch_config.nc
ncgen -o $PCONFIG $CDLCONFIG
