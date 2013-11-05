#!/bin/bash

set -x -e

NN=4
if [ $# -gt 0 ]; then
  NN="$1"
fi

PHI_LOW=5
PHI_HIGH=45
RATE_FACTOR=1e-24
PISM_CONFIG=aletsch_config.nc
OUTNAME=mb2008_testrun.nc
OUTNAME_TS=ts_${OUTNAME}
OUTNAME_EXTRA=extra_${OUTNAME}



Mz=50



if [ $# -gt 1 ] ; then
  if [ $2 -eq "1" ] ; then  # if user says "spinup.sh N 1" then use:
    echo "grid: coarsest"
      Mx=45
      My=86

  fi
  if [ $2 -eq "2" ] ; then  # if user says "spinup.sh N 2" then use:
    echo "grid: coarse"
      Mx=89
      My=169

  fi
  if [ $2 -eq "3" ] ; then  # if user says "spinup.sh N 3" then use:
    echo "grid: fine"
      Mx=176
      My=339

  fi
  if [ $2 -eq "4" ] ; then  # if user says "spinup.sh N 4" then use:
    echo "grid: finest"
      Mx=351
      My=679

  fi
fi




INNAME=pism_Aletsch_2009.nc

START=0
END=10

# mpirun -np 4 pismr -config_override aletsch_config.nc -boot_file $INNAME -Mx $Mx -My $My -Mz $Mx -Lz 1000 -sia_flow_law isothermal_glen -no_energy -surface elevation -ice_surface_temp -5,-25,0,4000 -climatic_mass_balance -1.55,1.1,0,2800,4800 -o_order zyx -ts_file ts_coarse.nc -ts_times $START:yearly:$END -o coarse.nc -o_size big -ys $START -ye $END

mpirun -np $NN pismr -config_override $PISM_CONFIG -boot_file $INNAME -Mx $Mx -My $My -Mz $Mx -Lz 1000 -ssa_sliding -pseudo_plastic -pseudo_plastic_q 0.333333 -pseudo_plastic_uthreshold 50 -sia_flow_law isothermal_glen -ssa_flow_law isothermal_glen -no_energy -surface given -surface_given_file mb2008.nc -o_order zyx -ts_file $OUTNAME_TS -topg_to_phi $PHI_LOW,$PHI_HIGH,2399,2400 -extra_file $OUTNAME_EXTRA -extra_times $START:monthly:$END -extra_vars csurf,cbase,dHdT,tauc,taud_mag,thk,usurf -ts_times $START:daily:$END -o $OUTNAME -o_size big -ys $START -ye $END


Mx=89
My=169

START=$END
END=110

INNAME=pism_Altesch_1880.nc
#mpirun -np 4 pismr -config_override aletsch_config.nc -boot_file $INNAME -regrid_file coarse.nc -regrid_vars thk -Mx $Mx -My $My -Mz $Mx -Lz 1000 -sia_flow_law isothermal_glen -no_energy -surface elevation -ice_surface_temp -5,-25,0,4000 -climatic_mass_balance -1.55,1.1,0,2800,4800 -o_order zyx -ts_file ts_fine.nc -ts_times $START:yearly:$END -o_size big -ys $START -ye $END -o fine.nc
