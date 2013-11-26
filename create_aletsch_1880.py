#!/usr/bin/env python

# Copyright (C) 2009-2013 the PISM Authors

## @package pism_python
# \author the PISM authors
# \brief Creates "from scratch" a boring dataset with the right format
# to use as a PISM bootstrapping file.
# \details Example use of Python for this purpose.
#
# Usage, including a minimal PISM call to bootstrap from this file:
#
# \verbatim $ pism_python.py  # creates foo.nc \endverbatim
# \verbatim $ pismr -boot_file foo.nc -Mx 41 -My 41 -Mz 21 -Lz 4000 -Mbz 5 -Lbz 500 -y 1 \endverbatim

import sys
import time
import numpy as np
import scipy.io

# try different netCDF modules
try:
    from netCDF4 import Dataset as CDF
except:
    from netCDF3 import Dataset as CDF

x,y,topg = np.loadtxt('data/aletsch_dem_base_50m.csv', unpack=True)

surface = scipy.io.loadmat('data/aletsch_surface_1880.mat')

usurf = surface['temp'][:,2]

# set up the grid:
Mx = 351
My = 679

X = x.reshape(My, Mx)
Y = y.reshape(My, Mx)
Topg = np.flipud(topg.reshape(My, Mx))
Usurf = np.flipud(usurf.reshape(My, Mx))

e0 = x.min()
e1 = x.max()
n0 = y.min()
n1 = y.max()
easting = np.linspace(e0, e1, Mx)
northing = np.linspace(n0, n1, My)

# create dummy fields
acab = np.zeros((Mx,My));
artm = np.zeros((Mx,My)) + 273.15 + 10.0; # 10 degrees Celsius

# Output filename
ncfile = 'pism_Aletsch_1880.nc'

# Write the data:
nc = CDF(ncfile, "w",format='NETCDF3_CLASSIC') # for netCDF4 module

# Create dimensions x and y
nc.createDimension("x", size=Mx)
nc.createDimension("y", size=My)

x_var = nc.createVariable("x", 'f4', dimensions=("x",))
x_var.units = "m";
x_var.long_name = "easting"
x_var.standard_name = "projection_x_coordinate"
x_var[:] = easting

y_var = nc.createVariable("y", 'f4', dimensions=("y",))
y_var.units = "m";
y_var.long_name = "northing"
y_var.standard_name = "projection_y_coordinate"
y_var[:] = northing

fill_value = np.nan

def def_var(nc, name, units, fillvalue):
    # dimension transpose is standard: "float thk(y, x)" in NetCDF file
    var = nc.createVariable(name, 'f', dimensions=("y", "x"), fill_value=fillvalue)
    var.units = units
    return var

bed_var = def_var(nc, "topg", "m", fill_value)
bed_var.standard_name = "bedrock_altitude"
bed_var[:] = Topg

thk = Usurf-Topg
thk[thk<0] = 0

thk_var = def_var(nc, "thk", "m", fill_value)
thk_var.standard_name = "land_ice_thickness"
thk_var[:] = thk

usurf_var = def_var(nc, "usurf", "m", fill_value)
usurf_var.standard_name = "surface_altitude"
usurf_var[:] = Usurf

acab_var = def_var(nc, "climatic_mass_balance", "m year-1", fill_value)
acab_var.standard_name = "land_ice_surface_specific_mass_balance"
acab_var[:] = acab

artm_var = def_var(nc, "ice_surface_temp", "K", fill_value)
artm_var[:] = artm

# set global attributes
nc.Conventions = "CF-1.4"
historysep = ' '
historystr = time.asctime() + ': ' + historysep.join(sys.argv) + '\n'
setattr(nc, 'history', historystr)

#nc.close()
print('  PISM-bootable NetCDF file %s written' % ncfile)

