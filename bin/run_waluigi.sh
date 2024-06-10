#!/bin/bash
#BSUB -q p_short
#BSUB -J waluigi
#BSUB -n 1
#BSUB -o log.waluigi_%J.out
#BSUB -e log.waluigi_%J.err
#BSUB -P 0601 
#BSUB -R "rusage[mem=3G]"

# exit on any error
#set -e

if [[ ! -z $CONDA_ENV ]]; then
    module purge 						# purge already active modules
    module --silent load anaconda/3-2022.10                     # load anaconda module
    echo "info: loading conda environment $CONDA_ENV"
    source $(conda info --base)/etc/profile.d/conda.sh          
    conda activate $CONDA_ENV                                   # active $CONDA_ENV module
fi

python -u /work/cmcc/js04724/waluigi/waluigi.py $WALUIGI_INPUT_FILE

