#!/usr/bin/env python

import numpy as np
import pylab as plt
from matplotlib import colors

Mx = 650
My = 1070

for year in [1957, 1980]:
    my_directory = 'T%i' % year
    vx = (np.loadtxt(my_directory + '/velsx.dat', 
                     skiprows=1)).reshape((My, Mx))
    vy = (np.loadtxt(my_directory + '/velsy.dat', 
                     skiprows=1)).reshape((My, Mx))

    dx = dy = 20
    x0 = 637475 + 10
    x1 = x0 + dx*Mx
    x = np.arange(x0, x1, dx)
    y0 = 135875 + 10
    y1 = y0 + dy*My
    y = np.arange(y0, y1, dy)

    v_mag = np.sqrt(vx**2 + vy**2)
    colorbar_label = 'm a$^{-1}$'
    vmin = 0.001
    vmax = 300
    norm = colors.Normalize(vmin=vmin, vmax=vmax)

    fig = plt.figure()
    ax = fig.add_subplot(111)
    p_mag = ax.pcolormesh(x, y, v_mag, norm=norm)
    s = 3
    p_stream = ax.streamplot(x, y, vx, vy, color='w', density=[s, s*My/Mx])
    cbar = plt.colorbar(p_mag)
    cbar.set_label(colorbar_label)
    cbar.solids.set_edgecolor("face")
    ax.set_aspect('equal')
    ax.set_xlim(637475, 650495)
    ax.set_ylim(135875, 157295)
    outfile = 'vels_jouve_%i.png'  % year
    fig.savefig(outfile, bbox_inches='tight', dpi=300)

