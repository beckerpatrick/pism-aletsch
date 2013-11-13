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

Mx = len(x)
My = len(y)

thk = np.squeeze(nc.variables['thk'][:])
topg = np.squeeze(nc.variables['topg'][:])

fig = plt.figure()
ax = fig.add_subplot(111)
p_mag = ax.pcolormesh(x, y, thk)
cbar = plt.colorbar(p_mag)
cbar.set_label('m')
cbar.solids.set_edgecolor("face")
ax.set_aspect('equal')
ax.set_xlim(645000, 648000)
ax.set_ylim(148000, 150000)
fig.savefig('boot_thk_pism.png', bbox_inches='tight', dpi=300)

usurf = topg + thk

fig = plt.figure()
ax = fig.add_subplot(111)
p_mag = ax.pcolormesh(x, y, usurf, vmin=2500, vmax=3000)
cbar = plt.colorbar(p_mag)
cbar.set_label('m')
cbar.solids.set_edgecolor("face")
ax.set_aspect('equal')
ax.set_xlim(645000, 648000)
ax.set_ylim(148000, 150000)
fig.savefig('boot_usurf_pism.png', bbox_inches='tight', dpi=300)

