#!/usr/bin/env python
# Copyright (C) 2013 Andy Aschwanden
#

import numpy as np
from dateutil import rrule
from dateutil.parser import parse
from datetime import datetime
import time
import numpy as np
from argparse import ArgumentParser
import gdal
import osr

try:
    import netCDF4 as netCDF
except:
    import netCDF3 as netCDF
NC = netCDF.Dataset
from netcdftime import utime


# Set up the option parser
parser = ArgumentParser()
parser.description = "Merge gdal-generated netCDF along time axis."
parser.add_argument("-a", "--start_date", dest="start_date",
                    help='''Start date in ISO format. Default=1961-1-1''',
                    default='1865-1-1')
parser.add_argument("-e", "--end_date", dest="end_date",
                    help='''End date in ISO format. Default=2010-1-1''',
                    default='2009-1-1')
parser.add_argument("-u", "--ref_unit", dest="ref_unit",
                    help='''Reference unit. Default=days. Use of months or
                    years is NOT recommended.''', default='days')
parser.add_argument("-d", "--ref_date", dest="ref_date",
                    help='''Reference date. Default=1865-1-1''',
                    default='1865-1-1')
parser.add_argument("-o", dest="out_file",
                    help="Name of the ouputfile.", default='mass_balance.nc')
parser.add_argument("-p", "--periodicity", dest="periodicity",
                    help='''periodicity, e.g. monthly, daily, etc. Default=yearly''',
                    default="yearly")

options = parser.parse_args()
start_date = parse(options.start_date)
end_date = parse(options.end_date)
out_file = options.out_file
ref_date = options.ref_date
ref_unit = options.ref_unit
periodicity = options.periodicity.upper()


time_units = ("%s since %s" % (ref_unit, ref_date))
# currently PISM only supports the gregorian standard calendar
# once this changes, calendar should become a command-line option
time_calendar = "standard"

cdftime = utime(time_units, time_calendar)

# create a dictionary so that we can supply the periodicity as a
# command-line argument.
pdict = {}
pdict['SECONDLY'] = rrule.SECONDLY
pdict['MINUTELY'] = rrule.MINUTELY
pdict['HOURLY'] = rrule.HOURLY
pdict['DAILY'] = rrule.DAILY
pdict['WEEKLY'] = rrule.WEEKLY
pdict['MONTHLY'] = rrule.MONTHLY
pdict['YEARLY'] = rrule.YEARLY
prule = pdict[periodicity]

# reference date from command-line argument
r = time_units.split(' ')[2].split('-')
refdate = datetime(int(r[0]), int(r[1]), int(r[2]))

# create list with dates from start_date until end_date with
# periodicity prule.
bnds_datelist = list(rrule.rrule(prule, dtstart=start_date, until=end_date))

# calculate the days since refdate, including refdate, with time being the
# mid-point value:
# time[n] = (bnds[n] + bnds[n+1]) / 2
bnds_interval_since_refdate = cdftime.date2num(bnds_datelist)
if (periodicity != 'YEARLY'):
    my_rule = rrule.DAILY
    datelist = list(rrule.rrule(my_rule, dtstart=start_date, until=end_date))
    days_per_year = np.diff(cdftime.date2num(datelist))
else:
    days_per_year = np.diff(bnds_interval_since_refdate)

    
time_interval_since_refdate = (bnds_interval_since_refdate[0:-1] +
                               np.diff(bnds_interval_since_refdate) / 2)




def create_outfile(f, outname):
    '''Generate output file based on information from the first input file
    '''
    
    geoT = f.GetGeoTransform()
    pxwidth = f.RasterXSize
    pxheight = f.RasterYSize
    ulx = geoT[0]
    uly = geoT[3]
    rezX = geoT[1]
    rezY = geoT[5]
    rx = ulx + pxwidth * rezX
    ly = uly + pxheight * rezY
    easting = np.arange(ulx+rezX/2, rx + rezX/2, rezX)
    northing = np.arange(ly+rezY/2, uly +rezY/2, -rezY)

    nc = NC(outname, 'w', format='NETCDF3_CLASSIC')
    # create a new dimension for bounds only if it does not yet exist
    time_dim = "time"
    if time_dim not in nc.dimensions.keys():
        nc.createDimension(time_dim)

    # create a new dimension for bounds only if it does not yet exist
    bnds_dim = "nb2"
    if bnds_dim not in nc.dimensions.keys():
        nc.createDimension(bnds_dim, 2)
    x_dim = 'x'
    if x_dim not in nc.dimensions.keys():
        nc.createDimension(x_dim, size=len(easting))
    y_dim = 'y'
    if y_dim not in nc.dimensions.keys():
        nc.createDimension(y_dim, size=len(northing))

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

    # create time variable
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


    cmb_var = nc.createVariable('climatic_mass_balance', 'f',
                                   dimensions= (time_dim, y_dim, x_dim),
        fill_value=fill_value)
    cmb_var.units = 'mm day-1'    
    cmb_var.long_name = "ice-equivalent surface mass balance (accumulation/ablation) rate" ;
    cmb_var.standard_name = "land_ice_surface_specific_mass_balance" ;
    cmb_var.cell_methods = 'time: sum'
    cmb_var.comment = '''From Matthias Huss. (1) Huss, M., Hock, R., Bauder, A. and Funk, M., 2010. 100-year glacier mass changes in the Swiss Alps linked to the Atlantic Multidecadal Oscillation. Geophyiscal Research Letters, 37, L10501, doi:10.1029/2010GL042616. (2) Huss, M., Bauder, A., Funk, M. and Hock, R. 2008. Determination of the seasonal mass balance of four Alpine glaciers since 1865, Journal of Geophysical Research, 113, F01015, doi:10.1029/2007JF000803.'''

    temp_var = nc.createVariable('ice_surface_temp', 'f',
                                 dimensions=(time_dim, y_dim, x_dim),
        fill_value=fill_value)
    temp_var.long_name = 'ice temperature at the ice surface'
    temp_var.units = 'degC'
    temp_var.comment = '''Made up.'''
    

    return nc

srs = osr.SpatialReference()
srs.ImportFromEPSG(21781)
proj4str = srs.ExportToProj4()

fill_value = -9999
ndv = -9999
counter = 0
k = 0
start_year = start_date.year
end_year = end_date.year
for year in range(start_year, end_year):
    my_path = "data/mass_balance"
    my_file = "mb" + str(year) + ".grid"
    filename = '/'.join([my_path, my_file])
    print('Processing file %s' % filename)
    f = gdal.Open(filename)
    if (counter == 0):
        nc = create_outfile(f, out_file)
    # Read data, convert from cm water equivalent per year to mm/day ice equivalent
    data = np.ma.masked_where(f.ReadAsArray()==ndv, f.ReadAsArray())
    nc.variables['climatic_mass_balance'][k,:] = np.flipud(data / 10 * (1000./910.) / days_per_year[k])
    nc.variables['ice_surface_temp'][k,:] = 0.
    counter += 1
    k += 1

# writing global attributes
script_command = ' '.join([time.ctime(), ':', __file__.split('/')[-1]])
nc.history = script_command
nc.projection = proj4str
nc.close()


