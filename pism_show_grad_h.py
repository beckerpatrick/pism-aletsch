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


hx = np.squeeze(nc.variables['h_x_i'][0,:]) # 0: only 1st time step
hy = np.squeeze(nc.variables['h_y_j'][0,:])
grad_h_mag = np.sqrt(hx**2 + hy**2)

fig = plt.figure()
ax = fig.add_subplot(111)
p_mag = ax.pcolormesh(x, y, grad_h_mag)
s = 3
step = 1
p_q = ax.quiver(x[::step], y[::step], hx[::step,::step], hy[::step,::step], color='w', units='xy', scale=0.005)
cbar = plt.colorbar(p_mag)
#cbar.set_label(colorbar_label)
#cbar.solids.set_edgecolor("face")
ax.set_aspect('equal')
ax.set_xlim(645000, 648000)
ax.set_ylim(148000, 150000)
fig.savefig('grad_h_pism.png', bbox_inches='tight', dpi=300)

taud_x = np.squeeze(nc.variables['taud_x'][0,:])
taud_y = np.squeeze(nc.variables['taud_y'][0,:])
taud_mag = np.squeeze(nc.variables['taud_mag'][0,:])

fig = plt.figure()
ax = fig.add_subplot(111)
p_mag = ax.pcolormesh(x, y, taud_mag)
step = 1
p_q = ax.quiver(x[::step], y[::step], taud_x[::step,::step], taud_y[::step,::step], color='w', units='xy')
cbar = plt.colorbar(p_mag)
cbar.set_label('Pa')
cbar.solids.set_edgecolor("face")
ax.set_aspect('equal')
ax.set_xlim(645000, 648000)
ax.set_ylim(148000, 150000)
fig.savefig('taud_pism.png', bbox_inches='tight', dpi=300)

thk = np.squeeze(nc.variables['thk'][0,:])

fig = plt.figure()
ax = fig.add_subplot(111)
p_mag = ax.pcolormesh(x, y, thk)
cbar = plt.colorbar(p_mag)
cbar.set_label('m')
cbar.solids.set_edgecolor("face")
ax.set_aspect('equal')
ax.set_xlim(645000, 648000)
ax.set_ylim(148000, 150000)
fig.savefig('thk_pism.png', bbox_inches='tight', dpi=300)

usurf = np.squeeze(nc.variables['usurf'][0,:])

fig = plt.figure()
ax = fig.add_subplot(111)
p_mag = ax.pcolormesh(x, y, usurf, vmin=2500, vmax=3000)
cbar = plt.colorbar(p_mag)
cbar.set_label('m')
cbar.solids.set_edgecolor("face")
ax.set_aspect('equal')
ax.set_xlim(645000, 648000)
ax.set_ylim(148000, 150000)
fig.savefig('usurf_pism.png', bbox_inches='tight', dpi=300)

