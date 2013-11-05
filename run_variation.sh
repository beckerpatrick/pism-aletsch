#!/bin/bash

set -e

SCRIPTNAME="#run_variation.sh"

NN=4  # default number of processors
if [ $# -gt 0 ] ; then  # if user says "psearise.sh 8" then NN = 8
  NN="$1"
fi

echo "$SCRIPTNAME                              NN = $NN"

Mx=45
My=86
SKIP=10

if [ $# -gt 1 ] ; then
  if [ $2 -eq "1" ] ; then  # if user says "spinup.sh N 1" then use:
    echo "# grid: coarsest"
      Mx=45
      My=86
      SKIP=10

  fi
  if [ $2 -eq "2" ] ; then  # if user says "spinup.sh N 2" then use:
    echo "# grid: coarse"
      Mx=89
      My=169
      SKIP=50

  fi
  if [ $2 -eq "3" ] ; then  # if user says "spinup.sh N 3" then use:
    echo "# grid: fine"
      Mx=176
      My=339
      SKIP=100

  fi
  if [ $2 -eq "4" ] ; then  # if user says "spinup.sh N 4" then use:
    echo "# grid: finest"
      Mx=351
      My=679
      SKIP=500
  fi
fi

# set output format:
#  $ export PISM_OFORMAT="netcdf4_parallel "
if [ -n "${PISM_OFORMAT:+1}" ] ; then  # check if env var is already set
  echo "$SCRIPTNAME                      PISM_OFORMAT = $PISM_OFORMAT  (already set)"
else
  PISM_OFORMAT="netcdf3"
  echo "$SCRIPTNAME                      PISM_OFORMAT = $PISM_OFORMAT"
fi
OFORMAT=$PISM_OFORMAT

# set MPIDO if using different MPI execution command, for example:
#  $ export PISM_MPIDO="aprun -n "
if [ -n "${PISM_MPIDO:+1}" ] ; then  # check if env var is already set
  echo "$SCRIPTNAME                      PISM_MPIDO = $PISM_MPIDO  (already set)"
else
  PISM_MPIDO="mpiexec -n "
  echo "$SCRIPTNAME                      PISM_MPIDO = $PISM_MPIDO"
fi

# check if env var PISM_DO was set (i.e. PISM_DO=echo for a 'dry' run)
if [ -n "${PISM_DO:+1}" ] ; then  # check if env var DO is already set
  echo "$SCRIPTNAME                         PISM_DO = $PISM_DO  (already set)"
else
  PISM_DO="" 
fi

# prefix to pism (not to executables)
if [ -n "${PISM_PREFIX:+1}" ] ; then  # check if env var is already set
  echo "$SCRIPTNAME                    PISM_PREFIX = $PISM_PREFIX  (already set)"
else
  PISM_PREFIX=""    # just a guess
  echo "$SCRIPTNAME                     PISM_PREFIX = $PISM_PREFIX"
fi

# set PISM_EXEC if using different executables, for example:
#  $ export PISM_EXEC="pismr -cold"
if [ -n "${PISM_EXEC:+1}" ] ; then  # check if env var is already set
  echo "$SCRIPTNAME                       PISM_EXEC = $PISM_EXEC  (already set)"
else
  PISM_EXEC="pismr"
  echo "$SCRIPTNAME                       PISM_EXEC = $PISM_EXEC"
fi

PISM="${PISM_PREFIX}${PISM_EXEC} -config_override aletsch_config.nc"

PHI_LOW=$PISM_PHI_LOW
PHI_HIGH=$PISM_PHI_HIGH
RATE_FACTOR=1e-24

Mz=50

GRID="-Mx $Mx -My $My -Mz $Mz -Lz 1000"
COUPLER="-surface given -surface_given_file mb2008.nc"
PHYSICS="-ssa_sliding -pseudo_plastic -pseudo_plastic_q 0.333333 -pseudo_plastic_uthreshold 50 -topg_to_phi $PHI_LOW,$PHI_HIGH,2399,2400 -sia_flow_law isothermal_glen -ssa_flow_law isothermal_glen -no_energy"
INNAME=pism_Aletsch_2009.nc

EXVARS="usurf,grounded_basal_flux_cumulative,bwat,nonneg_flux_cumulative,h_x,h_y,bmelt,strain_rates,csurf,lon,diffusivity,taud_mag,ocean_kill_flux_cumulative,climatic_mass_balance_cumulative,bwp,hardav,topg,velbar,tauc,lat,taud,bfrict,mask,Href,thk,temppabase,cbase,diffusivity_staggered,IcebergMask,tempicethk_basal,dHdt,flux_divergence"

START=0
END=0

# mpirun -np 4 pismr -config_override aletsch_config.nc -boot_file $INNAME -Mx $Mx -My $My -Mz $Mx -Lz 1000 -sia_flow_law isothermal_glen -no_energy -surface elevation -ice_surface_temp -5,-25,0,4000 -climatic_mass_balance -1.55,1.1,0,2800,4800 -o_order zyx -ts_file ts_coarse.nc -ts_times $START:yearly:$END -o coarse.nc -o_size big -ys $START -ye $END

# steady state (ss)
#OUTNAME=ss_low_${PHI_LOW}high${PHI_HIGH}-${RATE_FACTOR}.nc
#OUTNAME_EXTRA=ex_$OUTNAME

#echo "mpirun -np $NN pismr -config_override $PISM_CONFIG -boot_file $INNAME -Mx $Mx -My $My -Mz $Mx -Lz 1000 -ssa_sliding -pseudo_plastic -pseudo_plastic_q 0.333333 -pseudo_plastic_uthreshold 50 -sia_flow_law isothermal_glen -ssa_flow_law isothermal_glen -no_energy -surface given -surface_given_file mb2008.nc -o_order zyx -ts_file ts_sliding.nc -topg_to_phi $PHI_LOW,$PHI_HIGH,2399,2400  -ts_times $START:daily:$END -o $OUTNAME -o_size big -ys $START -ye $END"

OUTNAME=low_${PHI_LOW}high${PHI_HIGH}-${RATE_FACTOR}.nc
OUTNAME_EXTRA=ex_$OUTNAME
END=5

echo""
cmd="$PISM_MPIDO $NN $PISM -boot_file $INNAME -skip -skip_max $SKIP $GRID $COUPLER $PHYSICS -extra_file $OUTNAME_EXTRA -extra_times $START:monthly:$END -extra_vars $EXVARS -o_order zyx  -o $OUTNAME -o_size big -ys $START -ye $END"
$PISM_DO $cmd