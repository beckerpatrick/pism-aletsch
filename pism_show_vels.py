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

vx = np.squeeze(nc.variables['uvelsurf'][:])
vy = np.squeeze(nc.variables['vvelsurf'][:])
v_mag = np.sqrt(vx**2 + vy**2)


colorbar_label = 'm a$^{-1}$'
vmin = 0.001
vmax = 300
norm = colors.Normalize(vmin=vmin, vmax=vmax)

fig = plt.figure()
ax = fig.add_subplot(111)
p_mag = ax.pcolormesh(x, y, v_mag, norm=norm)
s = 3
#p_stream = ax.streamplot(x, y, vx, vy, color='w', density=[s, s*My/Mx])
cbar = plt.colorbar(p_mag)
cbar.set_label(colorbar_label)
cbar.solids.set_edgecolor("face")
ax.set_aspect('equal')
ax.set_xlim(637475, 650495)
ax.set_ylim(135875, 157295)
fig.savefig('vels_pism.png', bbox_inches='tight', dpi=300)
