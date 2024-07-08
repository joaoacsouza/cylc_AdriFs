#!/bin/bash -ilvx
#BSUB -q s_long
#BSUB -J adri_oceanvar
#BSUB -o log.oceanvar_%J.out
#BSUB -e log.oceanvar_%J.err
#BSUB -P 0601
#BSUB -R "rusage[mem=100G]"
##BSUB -M "10G" 
#BSUB -w 'done(oceanVar)'

echo "#######################"
export MEMORY_AFFINITY=MCM
export MP_WAIT_MODE=poll
export MP_SINGLE_THREAD=yes
export MP_PGMMODEL=mpmd
export MP_MSG_API=MPI,LAPI
export MP_POLLING_INTERVAL=30000000
export MP_SHARED_MEMORY=yes
export MP_EUILIB=us
export MP_EUIDEVICE=sn_all
export MP_TASK_AFFINITY=core
export KMP_AFFINITY="physical,0"
export OMP_NUM_THREADS=18
export KMP_STACKSIZE="200M"
export MPIMULTITASKMIX="ON"
export I_MPI_DEBUG=10

source $SHYMPI_DIR/shyfem.env 


export I_MPI_HYDRA_BOOTSTRAP=lsf
export I_MPI_HYDRA_BRANCH_COUNT=15
export I_MPI_HYDRA_COLLECTIVE_LAUNCH=1
. ${SUITE_WORK_DIR}/../bin/da/exp-descriptor.sh

WORKINGDIR=${SUITE_WORK_DIR}/../bin
OUTDIR=${SUITE_WORK_DIR}/../output/OceanVar 
SHYFEM_DIR={SHYMPI_DIR}

ACTUALINDEX=1
TSD=
TED=

#chunk=$(printf "%04d" $ACTUALINDEX)
#ln -sf ${SHYMPI_DIR}saniv1_chunk_${chunk}.nos ${WORKINGDIR}assim_save/saniv1_chunk_0000.nos
#fi

set -vx

ErrCheck()
{
if [ ! $1 -eq 0 ]; then
#   echo $1 > ${WORKINGDIR}/assim/index_A${ACTUALINDEX}.error
   exit $1
fi
}

LastErrToCheck=0

export PATH=${WORKINGDIR}:$PATH

cd ${WORKINGDIR}/../output/shyfem

#echo $LSB_JOBID > index_A${ACTUALINDEX}.jobid

sec_counter.py TagSecCounterAA_init

./da/3dvar.sh $WORKINGDIR $TED $MYE_TDVAR_DATA0 $nemo_n_mpi_proc $TDVAR_DATA1   # ${WORKINGDIR}/model #need revise, new input dir?
LastErrToCheck=$?

ErrCheck $LastErrToCheck