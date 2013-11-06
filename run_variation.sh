#!/bin/bash

set -e

SCRIPTNAME="#run_variation.sh"

NN=4  # default number of processors
if [ $# -gt 0 ] ; then  # if user says "psearise.sh 8" then NN = 8
  NN="$1"
fi

echo "$SCRIPTNAME                              NN = $NN"

# default values if no argument is given
Mx=45
My=86
SKIP=10
GS=400
if [ $# -gt 1 ] ; then
  if [ $2 -eq "1" ] ; then  # if user says "spinup.sh N 1" then use:
    echo "# grid: coarsest"
      Mx=45
      My=86
      SKIP=10
      GS=400
  fi
  if [ $2 -eq "2" ] ; then  # if user says "spinup.sh N 2" then use:
    echo "# grid: coarse"
      Mx=88
      My=169
      SKIP=50
      GS=200
  fi
  if [ $2 -eq "3" ] ; then  # if user says "spinup.sh N 3" then use:
    echo "# grid: fine"
      Mx=176
      My=339
      SKIP=100
      GS=100
  fi
  if [ $2 -eq "4" ] ; then  # if user says "spinup.sh N 4" then use:
    echo "# grid: finest"
      Mx=351
      My=679
      SKIP=500
      GS=50
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

# set PISM_CONFIG if using different config file, for example:
#  $ export PISM_CONFIG="aletsch_config.nc"
if [ -n "${PISM_CONFIG:+1}" ] ; then  # check if env var is already set
  echo "$SCRIPTNAME                       PISM_CONFIG = $PISM_CONFIG  (already set)"
else
  PISM_CONFIG="aletsch_config.nc"
  echo "$SCRIPTNAME                       PISM_CONFIG = $PISM_CONFIG"
fi

# set PISM_PHI_LOW if using different phi, for example:
#  $ export PISM_PHI_LOW="aletsch_config.nc"
if [ -n "${PISM_PHI_LOW:+1}" ] ; then  # check if env var is already set
  echo "$SCRIPTNAME                       PISM_PHI_LOW = $PISM_PHI_LOW  (already set)"
else
  PISM_PHI_LOW=5
  echo "$SCRIPTNAME                       PISM_PHI_LOW = $PISM_PHI_LOW"
fi

# set PISM_PHI_HIGH if using different phi, for example:
#  $ export PISM_PHI_HIGH=45
if [ -n "${PISM_PHI_HIGH:+1}" ] ; then  # check if env var is already set
  echo "$SCRIPTNAME                       PISM_PHI_HIGH = $PISM_PHI_HIGH  (already set)"
else
  PISM_PHI_HIGH=45
  echo "$SCRIPTNAME                       PISM_PHI_HIGH = $PISM_PHI_HIGH"
fi

# set PISM_PHI_RATEFACTOR if using different phi, for example:
#  $ export PISM_PHI_RATEFACTOR=45
if [ -n "${PISM_PHI_RATEFACTOR:+1}" ] ; then  # check if env var is already set
  echo "$SCRIPTNAME                       PISM_PHI_RATEFACTOR = $PISM_PHI_RATEFACTOR  (already set)"
else
  PISM_PHI_RATEFACTOR="2e-24"
  echo "$SCRIPTNAME                       PISM_PHI_RATEFACTOR = $PISM_PHI_RATEFACTOR"
fi

# cat stuff together
PISM="${PISM_PREFIX}${PISM_EXEC} -config_override $PISM_CONFIG"

PHI_LOW=$PISM_PHI_LOW
PHI_HIGH=$PISM_PHI_HIGH
RATE_FACTOR=$PISM_RATEFACTOR

Mz=50


GRID="-Mx $Mx -My $My -Mz $Mz -Lz 1000"
COUPLER="-surface given -surface_given_file mb2008.nc"
PHYSICS="-ssa_sliding -pseudo_plastic -pseudo_plastic_q 0.333333 -pseudo_plastic_uthreshold 50 -topg_to_phi $PHI_LOW,$PHI_HIGH,2399,2400 -sia_flow_law isothermal_glen -ssa_flow_law isothermal_glen -no_energy"
INNAME=pism_Aletsch_2009.nc

echo "$SCRIPTNAME             executable = '$PISM'"
echo "$SCRIPTNAME           full physics = '$PHYSICS'"
echo "$SCRIPTNAME                coupler = '$COUPLER'"
echo "$SCRIPTNAME                   grid = '$GRID' (= $GS m)"
echo ""

EXVARS="usurf,h_x,h_y,csurf,lon,diffusivity,taud_mag,hardav,topg,velbar,tauc,lat,taud,mask,thk,cbase,diffusivity_staggered,dHdt,flux_divergence"


OUTNAME=a${GS}m_low_${PHI_LOW}_high_${PHI_HIGH}-${RATE_FACTOR}.nc
OUTNAME_EXTRA=ex_$OUTNAME
START=0
END=5
EXSTEP=monthly

echo""
cmd="$PISM_MPIDO $NN $PISM -boot_file $INNAME -skip -skip_max $SKIP $GRID $COUPLER $PHYSICS -extra_file $OUTNAME_EXTRA -extra_times $EXSTEP -extra_vars $EXVARS -o_order zyx  -o $OUTNAME -o_size big -ys $START -ye $END"
$PISM_DO $cmd