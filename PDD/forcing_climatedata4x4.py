#!/usr/bin/env python

import numpy as np
import scipy
from netCDF4 import Dataset as CDF

from dateutil import rrule
from dateutil.parser import parse
from datetime import datetime
import time

# converts precipitation from mm d-1 to kg m-2 year-1
def precipitation_conversionMmPerDayToMPerS(prec_data):
    return prec_data * 0.000000012

try:
    import netCDF4 as netCDF
except:
    import netCDF3 as netCDF
NC = netCDF.Dataset
from netcdftime import utime


# Parameter festlegen
start_date = parse('01.01.1865')
end_date = parse('01.01.2008')
ref_date = parse('01.01.1864')
ref_unit = 'days'
prule = rrule.DAILY
netcdfFlavor = 'NETCDF3_CLASSIC'

outname = 'climateforcing_small.nc'

zeitspanne = (end_date - start_date).days
print('zeitspanne ' + str(zeitspanne))

# Klimadaten erfassen
hoeheDerWetterstation = 2766 # in Meter
tempGradient = -0.006
niederschlagGradient = 0.0003 # sollte 3% pro 100m sein
inname = "alet_bern_mc_prismloc_d.dat"


print('running forcing_climatdata4x4.py')
print ('process ' + inname)

# Klimadaten aus Textdatei einlesen
climatedata  = np.loadtxt(inname, skiprows=2)
year_row = 0
day_row = 1
temp_row = 3
prec_row = 4
anzahlTage = climatedata.shape[0]

# Klimadaten aufbereiten
print('converting climate data...')
temp_data = climatedata[:,temp_row]
prec_data = climatedata[:,prec_row]
prec_data = precipitation_conversionMmPerDayToMPerS(prec_data)

# Aufbau NetCDF-Datei
print('setup netCDF...')
nc = NC(outname, 'w', format=netcdfFlavor)


# create a new dimension for bounds only if it does not yet exist
print('creating time dimension...')
time_dim = "time"
if time_dim not in nc.dimensions.keys():
    nc.createDimension(time_dim)


# x und y erzeugen
print('creating spatial dimensions...')
#easting = np.arange(634000, 651500, 8750) # 2x2-Netz aufspannen (8750 *2 = 651500-634000)
#northing = np.arange(123600, 157500, 16950) # 2x2-Netz aufspannen (16950 *2 = 157500-123600)
easting_koor_i=634000
easting_koor_f=651500
easting_interval=8750
northing_koor_i=123600
northing_koor_f=157500
northing_interval=16950
easting = np.arange(easting_koor_i, easting_koor_f+easting_interval, easting_interval) # 2x2-Netz aufspannen (8750 *2 = 651500-634000)
northing = np.arange(northing_koor_i, northing_koor_f+northing_interval, northing_interval) # 2x2-Netz aufspannen (16950 *2 = 157500-123600)
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




time_units = ("%s since %s" % (ref_unit, ref_date))
time_calendar = "standard"
cdftime = utime(time_units, time_calendar)

# macht aus ref_date ein datetime-Objekt
refdateAsList = time_units.split(' ')[2].split('-')
refdate = datetime(int(refdateAsList[0]), int(refdateAsList[1]), int(refdateAsList[2]))

# erzeugt Liste von Datumseintraegen ab start_date bis end_date zu gegebener Periodizitaet prule
bnds_datelist = list(rrule.rrule(prule, dtstart=start_date, until=end_date))

# variable names consistent with PISM
time_var_name = "time"
bnds_var_name = "time_bnds"


# calculate the days since refdate, including refdate, with time being the
# mid-point value:
# time[n] = (bnds[n] + bnds[n+1]) / 2
print('calculateing the days since refdate...')
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
print('check if NC works...')
print nc.data_model

print('create air temp variable...')
temp_var = nc.createVariable('air_temp', 'f',dimensions=(time_dim, y_dim, x_dim),fill_value=fill_value)
temp_var.long_name = 'air temp 2m above the surface'
temp_var.units = 'degC'
temp_var.comment = '''test'''

print('create prec variable...')
prec_var = nc.createVariable('precipitation', 'f',dimensions=(time_dim, y_dim, x_dim),fill_value=fill_value)
prec_var.long_name = 'precipitation'
#prec_var.units = 'kg m-2 year-1'
prec_var.units = 'm s-1'
prec_var.comment = '''converted prec. data from mm/d to m s-1'''

print('create surf elevation variable...')
prec_var = nc.createVariable('surface_elevation', 'f',dimensions=(y_dim, x_dim),fill_value=fill_value)
prec_var.long_name = 'surface_elevation of the wheater station'
prec_var.units = 'm'
prec_var.comment = '''elevation field with surface elevation of the wheater station in every grid cell'''

print('create temp_lapse_rate variable...')
prec_var = nc.createVariable('temp_lapse_rate', 'f',dimensions=(),fill_value=tempGradient)
prec_var.long_name = 'temperature lapse rate'
prec_var.units = 'degC m-1'
prec_var.comment = '''no comment'''

print('create prec_lapse_rate variable...')
prec_var = nc.createVariable('precip_lapse_rate', 'f',dimensions=(),fill_value=niederschlagGradient)
prec_var.long_name = 'precipitation lapse rate'
prec_var.units = 'm-1'
prec_var.comment = '''no comment'''


# Temperatur und Niederschlag
start_day = 0
end_day = anzahlTage

print('create records...')
#for day in range(start_day,10): #ACHTUNG!!! ZUM TEST nur 10 Tage statt 53000 (end_day)
for day in range(0,zeitspanne):
    print("processing record {} of {}".format(day, zeitspanne))
    nc.variables['air_temp'][day,:] = temp_data[day]
    nc.variables['precipitation'][day,:] =prec_data[day]

# Feld mit surface elevation der Wetterstation
nc.variables['surface_elevation'][:] = hoeheDerWetterstation
nc.close()

print ('processing ' + inname + ' finished.')
