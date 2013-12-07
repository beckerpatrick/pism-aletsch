#!/usr/bin/env python

import numpy as np
import pylab as plt
from matplotlib import colors
from netCDF4 import Dataset as CDF
from argparse import ArgumentParser
from netcdftime import utime

parser = ArgumentParser()
parser.description = "A script to plot a variable in a netCDF file using imshow."
parser.add_argument("FILE", nargs='*')
options = parser.parse_args()
args = options.FILE

nc = CDF(args[0], 'r')

x = nc.variables['x'][:]
y = nc.variables['y'][:]
time = nc.variables['time']
time_units = time.units
time_calendar = time.calendar

cdftime = utime(time_units, time_calendar)
date = cdftime.num2date(time)
nt = len(time[:])

Mx = len(x)
My = len(y)
step = 1

for t in range(0,nt):

    print("Processing time step %i" %t)
    v_x = np.squeeze(nc.variables['uvelsurf'][t,:])
    v_y = np.squeeze(nc.variables['vvelsurf'][t,:])
    v_mag = np.squeeze(nc.variables['csurf'][t,:])

    year_str = date[t].ctime()

    thk = np.squeeze(nc.variables['thk'][t,:])
    mask = np.zeros_like(thk)
    mask[thk<1] = 1
    thk = np.ma.array(data=thk, mask=mask)
  
    fig = plt.figure()
    fig.clf()
    ax = fig.add_subplot(111)
    p_mag = ax.pcolormesh(x, y, v_mag, vmin=0, vmax=300)
#    p_q = ax.quiver(x[::step], y[::step], v_x[::step,::step], v_y[::step,::step], color='w', units='xy')
    cbar = plt.colorbar(p_mag)
    cbar.set_label('m/a')
    cbar.solids.set_edgecolor("face")
    ax.set_aspect('equal')
    ax.text(0.07,0.05,year_str,transform=ax.transAxes)
#    ax.set_xlim(645000, 648000)
    ax.set_ylim(135000, 158000)
    outname = ('csurf_%04d.png' % t)
    fig.savefig(outname, bbox_inches='tight', dpi=100)
    plt.close()
    del fig

    fig = plt.figure()
    fig.clf()
    ax = fig.add_subplot(111)
    p_mag = ax.pcolormesh(x, y, thk, vmin=0, vmax=900)
#    p_q = ax.quiver(x[::step], y[::step], v_x[::step,::step], v_y[::step,::step], color='w', units='xy')
    cbar = plt.colorbar(p_mag)
    ax.text(0.07,0.05,year_str,transform=ax.transAxes)
    cbar.set_label('m')
    cbar.solids.set_edgecolor("face")
    ax.set_aspect('equal')
#    ax.set_xlim(645000, 648000)
    ax.set_ylim(135000, 158000)
    outname = ('thk_%04d.png' % t)
    fig.savefig(outname, bbox_inches='tight', dpi=100)
    plt.close()
    del fig
    
nc.close()
