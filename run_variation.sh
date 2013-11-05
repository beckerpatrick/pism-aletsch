#!/bin/bash

set -x -e

NN=4
PHI_LOW=$PISM_PHI_LOW
PHI_HIGH=$PISM_PHI_HIGH
RATE_FACTOR=1e-24

if [ $# -gt 0 ]; then
  NN="$1"
fi

#Mx=351
#My=679

#Mx=176
#My=339

#Mx=89
#My=169


#Mx=45
#My=86

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


Mz=50

INNAME=pism_Aletsch_2009.nc


START=0
END=0

# mpirun -np 4 pismr -config_override aletsch_config.nc -boot_file $INNAME -Mx $Mx -My $My -Mz $Mx -Lz 1000 -sia_flow_law isothermal_glen -no_energy -surface elevation -ice_surface_temp -5,-25,0,4000 -climatic_mass_balance -1.55,1.1,0,2800,4800 -o_order zyx -ts_file ts_coarse.nc -ts_times $START:yearly:$END -o coarse.nc -o_size big -ys $START -ye $END

# steady state (ss)
#OUTNAME=ss_low_${PHI_LOW}high${PHI_HIGH}-${RATE_FACTOR}.nc
#OUTNAME_EXTRA=ex_$OUTNAME

#echo "mpirun -np $NN pismr -config_override $PISM_CONFIG -boot_file $INNAME -Mx $Mx -My $My -Mz $Mx -Lz 1000 -ssa_sliding -pseudo_plastic -pseudo_plastic_q 0.333333 -pseudo_plastic_uthreshold 50 -sia_flow_law isothermal_glen -ssa_flow_law isothermal_glen -no_energy -surface given -surface_given_file mb2008.nc -o_order zyx -ts_file ts_sliding.nc -topg_to_phi $PHI_LOW,$PHI_HIGH,2399,2400 -extra_file $OUTNAME_EXTRA -extra_times $START:monthly:$END -extra_vars csurf,cbase,tauc,taud_mag,thk,usurf -ts_times $START:daily:$END -o $OUTNAME -o_size big -ys $START -ye $END"

OUTNAME=low_${PHI_LOW}high${PHI_HIGH}-${RATE_FACTOR}.nc
OUTNAME_EXTRA=ex_$OUTNAME
END=5

echo "mpirun -np $NN pismr -config_override $PISM_CONFIG -boot_file $INNAME -Mx $Mx -My $My -Mz $Mx -Lz 1000 -ssa_sliding -pseudo_plastic -pseudo_plastic_q 0.333333 -pseudo_plastic_uthreshold 50 -sia_flow_law isothermal_glen -ssa_flow_law isothermal_glen -no_energy -surface_given_file mb2008.nc -o_order zyx -topg_to_phi $PHI_LOW,$PHI_HIGH,2399,2400 -o $OUTNAME -o_size big -ys $START -ye $END"