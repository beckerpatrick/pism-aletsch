#!/usr/bin/env python

import numpy as np
import pylab as plt
from matplotlib import colors
from netCDF4 import Dataset as CDF
from argparse import ArgumentParser

parser = ArgumentParser()
parser.description = "A script to plot a variable in a netCDF file using imshow."
parser.add_argument("FILE", nargs='*')
options = parser.parse_args()
args = options.FILE

nc = CDF(args[0], 'r')

x = nc.variables['x'][:]
y = nc.variables['y'][:]
time = nc.variables['time'][:]

nt = len(time)

Mx = len(x)
My = len(y)
step = 1

for t in range(0,nt):

    print("Processing time step %i" %t)
    taud_x = np.squeeze(nc.variables['taud_x'][t,:])
    taud_y = np.squeeze(nc.variables['taud_y'][t,:])
    taud_mag = np.squeeze(nc.variables['taud_mag'][t,:])

    usurf = np.squeeze(nc.variables['usurf'][t,:])

  
    fig = plt.figure()
    fig.clf()
    ax = fig.add_subplot(111)
    p_mag = ax.pcolormesh(x, y, usurf, vmin=2500, vmax=3000)
    p_q = ax.quiver(x[::step], y[::step], taud_x[::step,::step], taud_y[::step,::step], color='w', units='xy')
    cbar = plt.colorbar(p_mag)
    cbar.set_label('m')
    cbar.solids.set_edgecolor("face")
    ax.set_aspect('equal')
    ax.set_xlim(645000, 648000)
    ax.set_ylim(148000, 150000)
    outname = ('usurf_taud_%04d.png' % t)
    fig.savefig(outname, bbox_inches='tight', dpi=100)
    plt.close()
    del fig
    
nc.close()
