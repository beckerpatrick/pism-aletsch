#!/bin/bash

set -x -e

NN=4
if [ $# -gt 0 ]; then
  NN="$1"
fi

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
END=0.1

# mpirun -np 4 pismr -config_override aletsch_config.nc -boot_file $INNAME -Mx $Mx -My $My -Mz $Mx -Lz 1000 -sia_flow_law isothermal_glen -no_energy -surface elevation -ice_surface_temp -5,-25,0,4000 -climatic_mass_balance -1.55,1.1,0,2800,4800 -o_order zyx -ts_file ts_coarse.nc -ts_times $START:yearly:$END -o coarse.nc -o_size big -ys $START -ye $END

mpirun -np $NN pismr -config_override aletsch_config.nc -boot_file $INNAME -Mx $Mx -My $My -Mz $Mx -Lz 1000 -ssa_sliding -pseudo_plastic -pseudo_plastic_q 0.333333 -pseudo_plastic_uthreshold 50 -sia_flow_law isothermal_glen -ssa_flow_law isothermal_glen -no_energy -surface elevation -ice_surface_temp -5,-25,0,4000 -climatic_mass_balance -1.55,1.1,0,2800,4800 -o_order zyx -ts_file ts_sliding.nc -topg_to_phi 0,45,2399,2400 -extra_file extras.nc -extra_times $START:monthly:$END -extra_vars csurf,cbase,tauc,taud_mag,thk,usurf -ts_times $START:daily:$END -o sliding.nc -o_size big -ys $START -ye $END


Mx=89
My=169

START=$END
END=110

INNAME=pism_Altesch_1880.nc
#mpirun -np 4 pismr -config_override aletsch_config.nc -boot_file $INNAME -regrid_file coarse.nc -regrid_vars thk -Mx $Mx -My $My -Mz $Mx -Lz 1000 -sia_flow_law isothermal_glen -no_energy -surface elevation -ice_surface_temp -5,-25,0,4000 -climatic_mass_balance -1.55,1.1,0,2800,4800 -o_order zyx -ts_file ts_fine.nc -ts_times $START:yearly:$END -o_size big -ys $START -ye $END -o fine.nc
