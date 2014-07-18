#!/usr/bin/env python

import numpy as np
import scipy
from netCDF4 import Dataset as CDF

from dateutil import rrule
from dateutil.parser import parse
from datetime import datetime
import time


def precipitation_conversion(prec_data):
    return prec_data * 0.365

try:
    import netCDF4 as netCDF
except:
    import netCDF3 as netCDF
NC = netCDF.Dataset
from netcdftime import utime


# Parameter festlegen
start_date = parse('01.01.1865')
end_date = parse('01.01.2009')
ref_date = parse('01.01.1864')
ref_unit = 'days'
prule = rrule.YEARLY

outname = 'climateforcing.nc'

# Klimadaten erfassen
hoeheDerWetterstation = 2766 # in Meter
tempGradient = -0.006
niederschlagGradient = 0.0003 # sollte 3% pro 100m sein
inname = "alet_bern_mc_prismloc_d.dat"

time_units = ("%s since %s" % (ref_unit, ref_date))
time_calendar = "standard"
cdftime = utime(time_units, time_calendar)

# macht aus ref_date ein datetime-Objekt
refdateAsList = time_units.split(' ')[2].split('-')
refdate = datetime(int(refdateAsList[0]), int(refdateAsList[1]), int(refdateAsList[2]))

# erzeugt Liste von Datumseintraegen ab start_date bis end_date zu gegebener Periodizitaet prule
bnds_datelist = list(rrule.rrule(prule, dtstart=start_date, until=end_date))


print('running forcing_climatdata.py')
print ('process ' + inname)

# Klimadaten aus Textdatei einlesen
climatedata  = np.loadtxt(inname, skiprows=2)
year_row = 0
day_row = 1
temp_row = 3
prec_row = 4
anzahlTage = climatedata.shape[0]

# Klimadaten aufbereiten
temp_data = climatedata[:,temp_row]
prec_data = climatedata[:,prec_row]
prec_data = precipitation_conversion(prec_data)


# Aufbau NetCDF-Datei
nc = NC(outname, 'w', format='NETCDF3_CLASSIC')	

# create a new dimension for bounds only if it does not yet exist
time_dim = "time"
if time_dim not in nc.dimensions.keys():
    nc.createDimension(time_dim)


# x und y erzeugen
easting = np.arange(634000, 651500, 50)
northing = np.arange(123600, 157500, 50)
fill_value = -9999
x_dim = 'x'
if x_dim not in nc.dimensions.keys():
    #~ nc.createDimension(x_dim, size=5)
    nc.createDimension(x_dim, size=len(easting))
y_dim = 'y'
if y_dim not in nc.dimensions.keys():
    #~ nc.createDimension(y_dim, size=6)
    nc.createDimension(y_dim, size=len(northing))
    bnds_dim = "nb2"

if bnds_dim not in nc.dimensions.keys():
    nc.createDimension(bnds_dim, 2)


x_var = nc.createVariable(x_dim, 'f', dimensions=(x_dim,))
x_var.units = "m";
x_var.long_name = "easting"
x_var.standard_name = "projection_x_coordinate"
x_var[:] = easting

y_var = nc.createVariable(y_dim, 'f', dimensions=(y_dim,))
y_var.units = "m";
y_var.long_name = "northing"
y_var.standard_name = "projection_y_coordinate"
y_var[:] = northing


# variable names consistent with PISM
time_var_name = "time"
bnds_var_name = "time_bnds"


# calculate the days since refdate, including refdate, with time being the
# mid-point value:
# time[n] = (bnds[n] + bnds[n+1]) / 2
bnds_interval_since_refdate = cdftime.date2num(bnds_datelist)
my_rule = rrule.DAILY
datelist = list(rrule.rrule(my_rule, dtstart=start_date, until=end_date))
days_per_year = np.diff(cdftime.date2num(datelist))

    
time_interval_since_refdate = (bnds_interval_since_refdate[0:-1] +
                               np.diff(bnds_interval_since_refdate) / 2)

    
# time-Variable erzeugen
time_var = nc.createVariable(time_var_name, 'd', dimensions=(time_dim,))
time_var.bounds = bnds_var_name
time_var.units = time_units
time_var.calendar = time_calendar
time_var.standard_name = time_var_name
time_var.axis = "T"
time_var[:] = time_interval_since_refdate

# create time bounds variable
time_bnds_var = nc.createVariable(bnds_var_name, 'd', dimensions=(time_dim, bnds_dim))
time_bnds_var[:,0] = bnds_interval_since_refdate[0:-1]
time_bnds_var[:,1] = bnds_interval_since_refdate[1::]

# check ob NC funktioniert
print nc.data_model

temp_var = nc.createVariable('air_temp', 'f',dimensions=(time_dim, y_dim, x_dim),fill_value=fill_value)
temp_var.long_name = 'air temp 2m above the surface'
temp_var.units = 'degC'
temp_var.comment = '''test'''

prec_var = nc.createVariable('precipitation', 'f',dimensions=(time_dim, y_dim, x_dim),fill_value=fill_value)
prec_var.long_name = 'precipitation'
prec_var.units = 'kg m-2 year-1'
prec_var.comment = '''test'''

prec_var = nc.createVariable('surface_elevation', 'f',dimensions=(y_dim, x_dim),fill_value=fill_value)
prec_var.long_name = 'surface_elevation of the wheater station'
prec_var.units = 'm'
prec_var.comment = '''elevation field whith surface elevation of the wheater station in every grid cell'''

prec_var = nc.createVariable('temp_lapse_rate', 'f',dimensions=(),fill_value=tempGradient)
prec_var.long_name = 'temperature lapse rate'
prec_var.units = 'degC m-1'
prec_var.comment = '''no comment'''

prec_var = nc.createVariable('precip_lapse_rate', 'f',dimensions=(),fill_value=niederschlagGradient)
prec_var.long_name = 'precipitation lapse rate'
prec_var.units = 'm-1'
prec_var.comment = '''no comment'''


# Temperatur und Niederschlag
start_day = 0
end_day = anzahlTage

for day in range(start_day,100): #ACHTUNG!!! ZUM TEST nur 10 Tage statt 52000 (end_day)
#~ for day in range(start_day,end_day):
    nc.variables['air_temp'][day,:] = temp_data[day]
    nc.variables['precipitation'][day,:] =prec_data[day]
    print(str(day), 'von ', end_day)

# Feld mit surface elevation der Wetterstation
nc.variables['surface_elevation'][:] = hoeheDerWetterstation

#~ # Temperatur- und Niederschlagsgradient setzen
#~ nc.variables['temp_lapse_rate'][:] = tempGradient


nc.close()


