#!/bin/bash


#!/bin/bash

# Copyright (C) 2013 Andy Aschwanden
#


set -e  # exit on error

NN=4  # default number of processors
if [ $# -gt 0 ] ; then  # if user says "psearise.sh 8" then NN = 8
  NN="$1"
fi

echo "$SCRIPTNAME                              NN = $NN"

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


if [ -n "${PISM_TITLE:+1}" ] ; then  # check if env var is already set
  echo "$SCRIPTNAME                      PISM_TITLE = $PISM_TITLE  (already set)"
else
  PISM_TITLE="Aletschgletscher"
  echo "$SCRIPTNAME                      PISM_TITLE = $PISM_TITLE"
fi
TITLE=$PISM_TITLE


# default values if no argument is given
Mx=45
My=86
SKIP=10
GS=400
if [ $# -gt 1 ] ; then
  if [ $2 -eq "1" ] ; then  # if user says "spinup.sh N 2" then use:
    echo "# grid: coarse"
      Mx=88
      My=169
      SKIP=50
      GS=200
  fi
  if [ $2 -eq "2" ] ; then  # if user says "spinup.sh N 3" then use:
    echo "# grid: fine"
      Mx=176
      My=339
      SKIP=100
      GS=100
  fi
  if [ $2 -eq "3" ] ; then  # if user says "spinup.sh N 4" then use:
    echo "# grid: finest"
      Mx=351
      My=679
      SKIP=500
      GS=50
  fi
fi


# preprocess.sh generates pism_*.nc files; run it first
if [ -n "${PISM_DATANAME:+1}" ] ; then  # check if env var is already set
  echo "$SCRIPTNAME   PISM_DATANAME = $PISM_DATANAME  (already set)"
else
  PISM_DATANAME=pism_Aletsch_1880.nc
fi

INNAME=$PISM_DATANAME
CONFIG=aletsch_config.nc
OSIZE="big"

Mz=50
GRID="-Mx $Mx -My $My -Mz $Mz -Lz 1000"

PISM="${PISM_PREFIX}${PISM_EXEC} -title \"$TITLE\" -config_override aletsch_config.nc"
PHYSICS="-no_energy -ssa_sliding  -ssa_flow_law isothermal_glen -sia_flow_law isothermal_glen -ssa_sliding -topg_to_phi 5,45,2395,2400 -pseudo_plastic"
COUPLER="-surface given -surface_given_file aletsch_cmb_1865-2008.nc"

echo "$SCRIPTNAME             executable = '$PISM'"
echo "$SCRIPTNAME           full physics = '$PHYSICS'"
echo "$SCRIPTNAME                coupler = '$COUPLER'"
echo "$SCRIPTNAME                   grid = '$GRID' (= $GS m)"
echo ""

OUTNAME=aletsch_${GS}m_ssa_short.nc
EXNAME=ex_$OUTNAME
TSNAME=ts_$OUTNAME
EXVARS="usurf,h_x,h_y,bmelt,strain_rates,csurf,lon,diffusivity,taud_mag,topg,velbar,tauc,lat,taud,thk,cbase,diffusivity_staggered,dHdt,flux_divergence"

echo""
cmd="$PISM_MPIDO $NN $PISM -boot_file $INNAME $SKIP $GRID $PHYSICS $COUPLER -o_size $OSIZE -extra_times daily -extra_vars $EXVARS -extra_file $EXNAME -ts_times daily -ts_file $TSNAME -o $OUTNAME -time_file time_1880.nc -calendar gregorian -o_order zyx -o_format $OFORMAT"
$PISM_DO $cmd


STARTNAME=$OUTNAME
OUTNAME=aletsch_${GS}m_ssa.nc
EXNAME=ex_$OUTNAME
TSNAME=ts_$OUTNAME
EXVARS="usurf,grounded_basal_flux_cumulative,bwat,nonneg_flux_cumulative,h_x,h_y,bmelt,strain_rates,csurf,lon,diffusivity,taud_mag,ocean_kill_flux_cumulative,climatic_mass_balance_cumulative,bwp,hardav,topg,velbar,tauc,lat,taud,bfrict,mask,Href,thk,temppabase,cbase,diffusivity_staggered,IcebergMask,tempicethk_basal"

echo""
cmd="$PISM_MPIDO $NN $PISM -boot_file $INNAME -regrid_file $STARTNAME -regrid_vars thk $SKIP $GRID $PHYSICS $COUPLER -o_size $OSIZE -extra_times monthly -extra_vars $EXVARS -extra_file $EXNAME -ts_times daily -ts_file $TSNAME -o $OUTNAME -time_file time_1880-2000.nc -calendar gregorian -o_order zyx -o_format $OFORMAT"
$PISM_DO $cmd
