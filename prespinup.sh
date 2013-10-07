#!/bin/bash

Mx=351
My=679

Mx=176
My=339

Mx=86
My=169

Mz=100

INNAME=pism_Altesch_1880.nc

mpirun -np 4 pismr -config_override aletsch_config.nc -boot_file $INNAME -Mx $Mx -My $My -Mz $Mx -Lz 2000 -sia_flow_law isothermal_glen -no_energy -surface elevation -ice_surface_temp -5,-25,0,4000 -climatic_mass_balance -2,2,0,2700,5400 -o_size big -y 10