#!/bin/bash

gdalwarp -overwrite -s_srs epsg:21781 -te 633975 123575 651525 157525 -t_srs epsg:21781 -of netCDF -tr 50 50 -r bilinear data/aletsch_surface_2009.grid data/aletsch_surface_2009.nc
ncks -O pism_Aletsch_1880.nc pism_Aletsch_2009.nc
ncks -A -v Band1 data/aletsch_surface_2009.nc pism_Aletsch_2009.nc
ncap2 -O -s "thk=Band1-topg; where(thk<0) thk=0;" pism_Aletsch_2009.nc pism_Aletsch_2009.nc