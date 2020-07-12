#!/bin/sh
if [ -z ${USE_SLURM+x} ]; then
    export JULIA_NUM_THREADS=16
    julia $1 $2 $3
else
    export SIM_SCRIPT=$1
    export GRAPH_FILE=$2
    export RESULTS_FOLDER=$3
    export NUM_THREADS=8

    graph_name=$(basename -s .graphml ${GRAPH_FILE})
    script_name=$(basename -s .jl ${SIM_SCRIPT})
    job_name=${script_name}-${graph_name}

    envsubst \
        '${NUM_THREADS},${SIM_SCRIPT},${GRAPH_FILE},${RESULTS_FOLDER}' \
        <slurm_julia.sbatch | sbatch \
        --mail-user=jbeasley@stanford.edu \
        --mail-type=ALL \
        --job-name=${job_name} \
        --output=logs/out-${job_name}-%j.out \
        --time=24:00:00 \
        --nodes=1 \
        --cores-per-socket=${NUM_THREADS} \
        --mem=50000

fi
