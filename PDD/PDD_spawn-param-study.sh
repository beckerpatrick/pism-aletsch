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
SPAWNSCRIPT=run-hindcast.sh
CONTROL_SCRIPT="control_script.sh"
rm -f $CONTROL_SCRIPT


NN=4  # default number of processors
if [ $# -gt 0 ] ; then  # if user says "spawnparam.sh 8" then NN = 8
  NN="$1"
fi


if [ $# -gt 1 ] ; then
  RESOLUTION="$2"
fi


# set no of nodes
if [ -n "${PISM_NODES:+1}" ] ; then  # check if env var is already set
  echo "$SCRIPTNAME                    PISM_NODES = $PISM_NODES  (already set)"
else
  PISM_NODES=1
  echo "$SCRIPTNAME                     PISM_NODES = $PISM_NODES"
fi
NODES=$PISM_NODES

 SHEBANGLINE="#!/bin/bash"


CONFIG=aletsch_config.nc




      #SCRIPT="do_${ice_softnessVAL}.sh"
      SCRIPT="do_testatmo.sh"
      rm -f $SCRIPT
      EXPERIMENT=e_${ice_softnessVAL}
      CONFIG_FILE=${EXPERIMENT}_config.nc

      echo $SHEBANGLINE >> $SCRIPT
      echo >> $SCRIPT # add newline
      echo >> $SCRIPT # add newline

      export PISM_CONFIG=$CONFIG_FILE
      export PISM_EXPERIMENT=$EXPERIMENT
      export PISM_TITLE="Aletsch Flow Study"

      export PISM_RATEFACTOR=$ice_softnessVAL
      export PISM_CONFIG=$CONFIG_FILE

      # Run (all) the experiments
      
      PISM_DO=echo ./PDD_runhindcast.sh $NN $RESOLUTION >> $SCRIPT
      echo $PISM_DO

      #write (all) the experiments in the cluster control script
      echo "bsub -n ${NN} -W 12:00 -R \"rusage[scratch=10000]\" sh ${SCRIPT}" >> $CONTROL_SCRIPT
  
      echo "($SPAWNSCRIPT)  $SCRIPT written"
      

