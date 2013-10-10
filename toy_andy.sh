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


# defaults to coarse grid choices
GRID='-Mx 88 -My 169 -Mz 50 -Lz 1000'
SKIP='-skip -skip_max 100'
GS=200


# preprocess.sh generates pism_*.nc files; run it first
if [ -n "${PISM_DATANAME:+1}" ] ; then  # check if env var is already set
  echo "$SCRIPTNAME   PISM_DATANAME = $PISM_DATANAME  (already set)"
else
  PISM_DATANAME=pism_Aletsch_1880.nc
fi

INNAME=$PISM_DATANAME
CONFIG=aletsch_config.nc
OSIZE="medium"


PISM="${PISM_PREFIX}${PISM_EXEC} -title \"$TITLE\" -config_override aletsch_config.nc"
PHYSICS="-no_energy -ssa_sliding  -ssa_flow_law isothermal_glen -sia_flow_law isothermal_glen -ssa_sliding -topg_to_phi 5,40,2000,2400 -pseudo_plastic"
COUPLER="-surface elevation -ice_surface_temp -5,-25,0,4000 -climatic_mass_balance -2,1.25,1600,2800,4800 -climatic_mass_balance_limits -50,1.25"

echo "$SCRIPTNAME             executable = '$PISM'"
echo "$SCRIPTNAME           full physics = '$PHYSICS'"
echo "$SCRIPTNAME                coupler = '$COUPLER'"
echo "$SCRIPTNAME                   grid = '$GRID' (= $GS m)"
echo ""

OUTNAME=aletsch_${GS}m_ssa.nc
EXNAME=ex_$OUTNAME
TSNAME=ts_$OUTNAME
EXVARS="usurf,grounded_basal_flux_cumulative,bwat,nonneg_flux_cumulative,h_x,h_y,bmelt,strain_rates,csurf,lon,diffusivity,taud_mag,ocean_kill_flux_cumulative,climatic_mass_balance_cumulative,bwp,hardav,topg,velbar,tauc,lat,taud,bfrict,mask,Href,thk,temppabase,cbase,diffusivity_staggered,IcebergMask,tempicethk_basal"

echo""
cmd="$PISM_MPIDO $NN $PISM -boot_file $INNAME $SKIP $GRID $PHYSICS $COUPLER -o_size $OSIZE -extra_times monthly -extra_vars $EXVARS -extra_file $EXNAME -ts_times daily -ts_file $TSNAME -o $OUTNAME -y 50 -o_format $OFORMAT"
$PISM_DO $cmd

STARTNAME=$OUTNAME
GRID='-Mx 176 -My 339 -Mz 50 -Lz 1000'
GS=100
OUTNAME=aletsch_${GS}m_ssa.nc
EXNAME=ex_$OUTNAME
TSNAME=ts_$OUTNAME
EXVARS="usurf,grounded_basal_flux_cumulative,bwat,nonneg_flux_cumulative,h_x,h_y,bmelt,strain_rates,csurf,lon,diffusivity,taud_mag,ocean_kill_flux_cumulative,climatic_mass_balance_cumulative,bwp,hardav,topg,velbar,tauc,lat,taud,bfrict,mask,Href,thk,temppabase,cbase,diffusivity_staggered,IcebergMask,tempicethk_basal"

echo""
cmd="$PISM_MPIDO $NN $PISM -boot_file $INNAME -regrid_file $STARTNAME -regrid_vars thk $SKIP $GRID $PHYSICS $COUPLER -o_size $OSIZE -extra_times monthly -extra_vars $EXVARS -extra_file $EXNAME -ts_times daily -ts_file $TSNAME -o $OUTNAME -y 5 -o_format $OFORMAT"
$PISM_DO $cmd
