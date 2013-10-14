#!/bin/bash

set -x -e

# run ./preprocess.sh 1 if you haven't CDO compiled with OpenMP
NN=4  # default number of processors
if [ $# -gt 0 ] ; then
  NN="$1"
fi

srs="epsg:21781"
python create_aletsch.py
# nc2cdo.py from pism/util/ is your friend:
# it can calculate lon/lat and bounds based on the mapping variable, the global
# attribute 'projection' and as a command line option --srs. 
# '--srs' accepts valid proj4 strings and epsg codes.
nc2cdo.py --srs $srs pism_Aletsch_1880.nc
cmb_prefix=aletsch_cmb_1865-2008
cmb_file_orig=${cmb_prefix}_orig.nc
cmb_file_out=${cmb_prefix}.nc
./grid2nc.py -o ${cmb_file_orig}
nc2cdo.py --srs $srs ${cmb_file_orig}
# CDO is forgetful: it drops x and y variables because lat/lon is present
if [ [$NN == 1] ] ; then
    cdo remapcon,pism_Aletsch_1880.nc ${cmb_file_orig} ${cmb_file_out}
else
    cdo -P $NN remapcon,pism_Aletsch_1880.nc ${cmb_file_orig} ${cmb_file_out}
fi

# we use the missing value as a very negative mass balance outside the glacier to remove excess ice
ncks -A -v x,y pism_Aletsch_1880.nc ${cmb_file_out}
ncatted -a _FillValue,,d,, -a missing_value,,d,, ${cmb_file_out}
# PISM stalls with compressed netCDF4, but why?
ncks -O -3 ${cmb_file_out} ${cmb_file_out}
# config file
CDLCONFIG=aletsch_config.cdl
PCONFIG=aletsch_config.nc
ncgen -o $PCONFIG $CDLCONFIG
