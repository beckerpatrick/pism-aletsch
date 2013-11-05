#!/bin/bash

# Copyright (C) 2009-2011 Ed Bueler and Andy Aschwanden

#  creates 9 scripts each with NN processors and (potentially) submits them
#    on pacman.arsc.edu

#  needs rawparamscript, trimparam.sh

#  usage: to use NN=64 processors, nodes 16, and duration 16:00:00,
#     $ export PISM_WALLTIME=16:00:00
#     $ export PISM_NODES=16
#     $ ./spawnparam.sh 64
#     (assuming you like the resulting scripts)
#     $ ./submitparam.sh      ### <--- REALLY SUBMITS using qsub

#  see submitparam.sh

# initially generates 3x3x3=27 scripts

set -e # exit on error
SPAWNSCRIPT=run_script.sh



NN=4  # default number of processors
if [ $# -gt 0 ] ; then  # if user says "spawnparam.sh 8" then NN = 8
  NN="$1"
fi

# set wallclocktime
if [ -n "${PISM_WALLTIME:+1}" ] ; then  # check if env var is already set
  echo "$SCRIPTNAME                    PISM_WALLTIME = $PISM_WALLTIME  (already set)"
else
  PISM_WALLTIME=48:00:00
  echo "$SCRIPTNAME                     PISM_WALLTIME = $PISM_WALLTIME"
fi
WALLTIME=$PISM_WALLTIME

# set no of nodes
if [ -n "${PISM_NODES:+1}" ] ; then  # check if env var is already set
  echo "$SCRIPTNAME                    PISM_NODES = $PISM_NODES  (already set)"
else
  PISM_NODES=1
  echo "$SCRIPTNAME                     PISM_NODES = $PISM_NODES"
fi
NODES=$PISM_NODES

 SHEBANGLINE="#!/bin/bash"
MPIQUEUELINE="#PBS -q standard_4"
 MPITIMELINE="#PBS -l walltime=$WALLTIME"
 MPISIZELINE="#PBS -l nodes=$NODES:ppn=4"
  MPIOUTLINE="#PBS -j oe"

# params in nested for loop:
#   ice_softness      	2e-25   1e-24   5e-24
#   phi_low  		2       5       10
#   phi_high            35      45      55

CONFIG=aletsch_config.nc



for ice_softnessVAL in 2e-25 1e-24 5e-24
do

  for phi_lowVAL in 2 5 10
  do

    for phi_highVAL in 35 45 55
    do

      SCRIPT="do_${ice_softnessVAL}_${phi_lowVAL}_${phi_highVAL}.sh"
      rm -f $SCRIPT
      EXPERIMENT=e_${ice_softnessVAL}_phi_low_${phi_lowVAL}_phi_high_${phi_highVAL}
      CONFIG_FILE=${EXPERIMENT}_config.nc
      ncks -O $CONFIG $CONFIG_FILE

      ncatted -a ice_softness,pism_overrides,o,f,$ice_softnessVAL $CONFIG_FILE
# /         -a pseudo_plastic_q,pism_overrides,o,d,$(float_eval "$phi_lowVAL / 100") \
#          -a till_pw_fraction,pism_overrides,o,d,$(float_eval "$phi_highVAL / 100") $CONFIG_FILE

      # insert preamble
      echo $SHEBANGLINE >> $SCRIPT
      echo >> $SCRIPT # add newline
      echo $MPIQUEUELINE >> $SCRIPT
      echo $MPITIMELINE >> $SCRIPT
      echo $MPISIZELINE >> $SCRIPT
      echo $MPIOUTLINE >> $SCRIPT
      echo >> $SCRIPT # add newline
      echo "cd \$PBS_O_WORKDIR" >> $SCRIPT
      echo >> $SCRIPT # add newline

      export PISM_CONFIG=$CONFIG_FILE
      export PISM_EXPERIMENT=$EXPERIMENT
      export PISM_TITLE="Aletsch Flow Study"

      export PISM_PHI_LOW=$phi_lowVAL
      export PISM_PHI_HIGH=$phi_highVAL
      export PISM_RATEFACTOR=$ice_softnessVAL

# Run (all) the experiments
      
      ./run_variation.sh $NN $2 >> $SCRIPT

      echo "($SPAWNSCRIPT)  $SCRIPT written"
      
    done
  done
done


