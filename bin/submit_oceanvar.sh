#!/bin/bash -ilvx
#BSUB -x 
#BSUB -q s_long
#BSUB -J adri_oceanvar
#BSUB -o log.oceanvar_%J.out
#BSUB -e log.oceanvar_%J.err
#BSUB -P 0601
#BSUB -R "rusage[mem=100G]"
##BSUB -M "10G" 
#BSUB -w 'done(saniv1_729)'

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

#module purge
#module load intel19.5/19.5.281 impi19.5/19.5.281 impi19.5/netcdf/C_4.7.2-F_4.5.2_CXX_4.3.1
#module load intel19.5/nco/4.8.1 anaconda/3.7
#
#module list

export I_MPI_HYDRA_BOOTSTRAP=lsf
export I_MPI_HYDRA_BRANCH_COUNT=15
export I_MPI_HYDRA_COLLECTIVE_LAUNCH=1
. /work/opa/ms11120/EXPERIMENTS/OceanVar_SHYFEM/OceanVar/exp-descriptor.sh

WORKINGDIR=/work/opa/ms11120/EXPERIMENTS/OceanVar_SHYFEM/OceanVar/
OUTDIR=/work/opa/ms11120/EXPERIMENTS/OceanVar_SHYFEM/OceanVar/output/output_chunk_0000
SHYFEM_DIR=/work/opa/ms11120/EXPERIMENTS/OceanVar_SHYFEM/SHYFEM/
#MVFILE=/work/opa/ms11120/EXPERIMENTS/OceanVar_SHYFEM/OceanVar/assim_save/{ANINCR.NC,OBSSTAT*,COST.DAT,3DVAR*,LOG*}
#MVFILE="mv ${MVFILE} ${OUTDIR}"

ACTUALINDEX=1
TSD=
TED=

chunk=$(printf "%04d" $ACTUALINDEX)
#if [${ACTUALINDEX} -eq 0]; then
#cp ${SHYFEM_DIR}saniv1_chunk_${ACTUALINDEX}.nos ${WORKINGDIR}assim_save
ln -sf ${SHYFEM_DIR}saniv1_chunk_${chunk}.nos ${WORKINGDIR}assim_save/saniv1_chunk_0000.nos
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

export PATH=${WORKINGDIR}/tmp:$PATH


#rm -Rf ${WORKINGDIR}/assim_${TSD}
#mkdir ${WORKINGDIR}/assim_${TSD}
cd ${WORKINGDIR}/assim_save

#echo $LSB_JOBID > index_A${ACTUALINDEX}.jobid

sec_counter.py TagSecCounterAA_init

#CallRebuildT   #for 3dvar 101
#for 3dvar 103
#required to launch shuffle_obs
#for file in `ls ../prepobs_${TSD}/???MIS_*.NC ../prepobs_${TSD}/OBS_TAB.DAT`; do
#   ln -s $file
#done

# rebuild the partial files in the temporary folder under rebuilt/
Cmd="../tmp/aig"`expr ${ACTUALINDEX} \/ 100`"/Job_EXP_R${ACTUALINDEX}_Ta"
echo $Cmd
eval $Cmd

../tmp/3dvar.sh $WORKINGDIR $TED $MYE_TDVAR_DATA0 $nemo_n_mpi_proc $TDVAR_DATA1   # ${WORKINGDIR}/model #need revise, new input dir?
LastErrToCheck=$?

ErrCheck $LastErrToCheck

#eval "$MVFILE"

#if [ ${tdvar_n_mpi_proc} -gt 0 ]; then
#   export PYTHONPATH=$PYTHONPATH:${WORKINGDIR}/tmp/
#   if [ ! _${TDVAROnlyMisfit} = "_yes" ]; then
      # Merge the increment files
#   ../tmp/Merge_anincr.py ${WORKINGDIR}/assim_${TSD}/
#   fi
   
   # Merge the obsstat files
#   ../tmp/Merge_obsstats.py $tdvar_n_mpi_proc ${WORKINGDIR}/assim_${TSD}/
#fi

# Merge the log files
#mv COST.DAT COST.DAT.0000
#for file in COST.DAT.*; do 
#   echo $file >> COST.DAT
#   cat $file >> COST.DAT
#done
#mv LOG_3DVAR LOG_3DVAR.0000
#for file in LOG_3DVAR.*; do
#   cat $file >> LOG_3DVAR
#done

#if [ _${output_sort} = _"yes" ]; then
#   OUTPUTDIR=$WORKINGDIR/output/${TSD:0:6}
#else
#   OUTPUTDIR=$WORKINGDIR/output
#fi
#[ -d ${OUTPUTDIR} ] || mkdir -p ${OUTPUTDIR}

#if [ _${output_sort} = _"yes" ]; then
#   LOGDIR=$WORKINGDIR/log/${TSD:0:6}
#else
#   LOGDIR=$WORKINGDIR/log
#fi
#[ -d ${LOGDIR} ] || mkdir -p ${LOGDIR}

#mv COST.DAT $LOGDIR/COST.DAT.${TSD}
#check_file.sh exist $LOGDIR/COST.DAT.${TSD}
#ErrCheck $?
#mv LOG_3DVAR $LOGDIR/assim.LOG_3DVAR.${TSD}
#check_file.sh exist $LOGDIR/assim.LOG_3DVAR.${TSD}
#ErrCheck $?

#python ../tmp/check_obs.py ../prepobs_${TSD}/OBS_TAB.DAT ${nemo_n_mpi_proc}
#if [ $? -eq 0 ]; then #case of valid obs
#   mv OBSSTAT_SCREEN.NC $OUTPUTDIR/OBSSTAT_SCREEN.NC.${TSD}
#   check_file.sh exist $OUTPUTDIR/OBSSTAT_SCREEN.NC.${TSD}
#   ErrCheck $?
#else
#   echo "WARNING no valid obs this day - ${TSD} "
#fi

#if [ ! _${TDVAROnlyMisfit} = "_yes" ]; then
#   mv ANINCR.NC $OUTPUTDIR/ANINCR.NC.${TED}00
#   check_file.sh exist $OUTPUTDIR/ANINCR.NC.${TED}00
#   ErrCheck $?
#   python ../tmp/check_anincr.py $OUTPUTDIR/ANINCR.NC.${TED}00
#   if [ $? -eq 0 ]; then #case of assimilated obs
#      mv OBSSTAT.NC $OUTPUTDIR/OBSSTAT.NC.${TSD}
#      check_file.sh exist $OUTPUTDIR/OBSSTAT.NC.${TSD}
#      ErrCheck $?
#   else
#      echo "WARNING no assimilated obs this day - ${TSD} "
#   fi
#fi 

#rm -Rf ${WORKINGDIR}/assim_${TSD}

#sec_counter.py TagSecCounterAF_check_done_DONE
#sec_counter.py TagSecCounterAE_post_done_DONE

