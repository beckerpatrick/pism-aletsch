#!/bin/bash

set -e

SCRIPTNAME="#run-hindcast.sh"

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
  if [ $2 -eq "1" ] ; then
    echo "# grid: coarse"
    # approx. 200m
      Mx=88
      My=169
      SKIP=50
      GS=200
  fi
  if [ $2 -eq "2" ] ; then
    echo "# grid: fine"
    # 100m
      Mx=176
      My=340
      SKIP=100
      GS=100
  fi
  if [ $2 -eq "3" ] ; then
    echo "# grid: finest"
    # 50m (native)
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

# set PISM_U_THRESHOLD if using different phi, for example:
#  $ export PISM_U_THRESHOLD=45
if [ -n "${PISM_U_THRESHOLD:+1}" ] ; then  # check if env var is already set
  echo "$SCRIPTNAME                       PISM_U_THRESHOLD = $PISM_U_THRESHOLD  (already set)"
else
  PISM_U_THRESHOLD=50
  echo "$SCRIPTNAME                       PISM_U_THRESHOLD = $PISM_U_THRESHOLD"
fi

# set PISM_RATEFACTOR if using different phi, for example:
#  $ export PISM_RATEFACTOR=2e-24
if [ -n "${PISM_RATEFACTOR:+1}" ] ; then  # check if env var is already set
  echo "$SCRIPTNAME                       PISM_RATEFACTOR = $PISM_RATEFACTOR  (already set)"
else
  PISM_RATEFACTOR="2e-24"
  echo "$SCRIPTNAME                       PISM_RATEFACTOR = $PISM_RATEFACTOR"
fi

# cat stuff together
PISM="${PISM_PREFIX}${PISM_EXEC} -config_override $PISM_CONFIG"

PHI_LOW=$PISM_PHI_LOW
U_THRESHOLD=$PISM_U_THRESHOLD
RATE_FACTOR=$PISM_RATEFACTOR

Mz=50


GRID="-Mx $Mx -My $My -Mz $Mz -Lz 1000"
COUPLER="-surface given -surface_given_file aletsch_cmb_1865-2008.nc"
PHYSICS="-ssa_sliding -pseudo_plastic -pseudo_plastic_q 0.333333 -pseudo_plastic_uthreshold $U_THRESHOLD -topg_to_phi $PHI_LOW,45,2399,2400 -sia_flow_law isothermal_glen -ssa_flow_law isothermal_glen -no_energy"
INNAME=pism_Aletsch_1880.nc

echo "$SCRIPTNAME             executable = '$PISM'"
echo "$SCRIPTNAME           full physics = '$PHYSICS'"
echo "$SCRIPTNAME                coupler = '$COUPLER'"
echo "$SCRIPTNAME                   grid = '$GRID' (= $GS m)"
echo ""

EXVARS="usurf,h_x,h_y,csurf,lon,diffusivity,taud_mag,hardav,topg,velbar,tauc,lat,taud,mask,thk,cbase,dHdt,flux_divergence,velbase,velsurf"

OUTNAME=a${GS}m_low_${PHI_LOW}_high_${U_THRESHOLD}_${RATE_FACTOR}_1880-2008.nc
OUTNAME_EXTRA=ex_$OUTNAME
EXSTEP=monthly
OUTNAME_TS=ts_$OUTNAME

echo""
cmd="$PISM_MPIDO $NN $PISM -boot_file $INNAME -skip -skip_max $SKIP $GRID $COUPLER $PHYSICS -ts_file $OUTNAME_TS -ts_times daily -extra_file $OUTNAME_EXTRA -extra_times $EXSTEP -extra_vars $EXVARS -o_order zyx  -o $OUTNAME -o_size big -time_file time_1880-2008.nc -calendar gregorian  2>&1 | tee job.\${PBS_JOBID}"
$PISM_DO $cmd
