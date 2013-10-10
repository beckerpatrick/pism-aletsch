#!/bin/bash

Mx=351
My=679

Mx=176
My=339

Mx=89
My=169



Mx=45
My=86

Mz=50

INNAME=pism_Altesch_1880.nc

START=0
END=100

mpirun -np 4 pismr -config_override aletsch_config.nc -boot_file $INNAME -Mx $Mx -My $My -Mz $Mx -Lz 1000 -sia_flow_law isothermal_glen -no_energy -surface elevation -ice_surface_temp -5,-25,0,4000 -climatic_mass_balance -1.55,1.1,0,2800,4800 -o_order zyx -ts_file ts_coarse.nc -ts_times $START:yearly:$END -o coarse.nc -o_size big -ys $START -ye $END

Mx=89
My=169

START=$END
END=110

INNAME=pism_Altesch_1880.nc
mpirun -np 4 pismr -config_override aletsch_config.nc -boot_file $INNAME -regrid_file coarse.nc -regrid_vars thk -Mx $Mx -My $My -Mz $Mx -Lz 1000 -sia_flow_law isothermal_glen -no_energy -surface elevation -ice_surface_temp -5,-25,0,4000 -climatic_mass_balance -1.55,1.1,0,2800,4800 -o_order zyx -ts_file ts_fine.nc -ts_times $START:yearly:$END -o_size big -ys $START -ye $END -o fine.nc