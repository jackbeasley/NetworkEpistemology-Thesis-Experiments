#!/bin/bash -l
# NOTE the -l flag!
#    see https://stackoverflow.com/questions/20499596/bash-shebang-option-l

#-----------------------
# script
#-----------------------

hostname

if [ -z ${SLURM_JOB_ID+x} ]
then
    echo "Starting job locally"
else
    echo "Starting job ${SLURM_JOB_ID}"
    module load julia/1.3.1
fi
# run the script
JULIA_NUM_THREADS=${NUM_THREADS} julia ${SIM_SCRIPT} ${GRAPH_FILE} ${RESULTS_FOLDER}

