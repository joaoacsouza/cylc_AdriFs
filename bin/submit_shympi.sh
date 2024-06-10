#BSUB -x 
#BSUB -q p_short
#BSUB -J adri
#BSUB -n 144
#BSUB -o log.adri_%J.out
#BSUB -e log.adri_%J.err
#BSUB -P 0601 

# load modules
source $SHYMPI_DIR/shyfem.env #shympi_env

export RUNTIME_OPTS="-ksp_type bcgs -ksp_rtol 1e-15 -ksp_atol 1e-12 "
#export RUNTIME_OPTS="-ksp_type gmres -ksp_rtol 1e-18 -ksp_atol 1e-15 "
# additional parameters for monitoring
#export RUNTIME_OPTS="$RUNTIME_OPTS -ksp_converged_reason"   # -ksp_monitor  
#export RUNTIME_OPTS="$RUNTIME_OPTS -history log.petsc_history "      # save every petsc's output in a logfile. 
#export RUNTIME_OPTS="$RUNTIME_OPTS -info log.petsc_info "            # details about algos, data structuctures, etc
#export RUNTIME_OPTS="$RUNTIME_OPTS -log_summary "                    # performance statistics at the program's termination
#export RUNTIME_OPTS="$RUNTIME_OPTS -log_trace log.petsc_trace "      # trace start and end for all petsc events.


# default values (from PETSc side): rtol=1e-5, atol=1e-50, dtol=1e5, maxits=1e4
# bcgs does't need a precodintioner?

if [ "$I_MPI_HYDRA_BOOTSTRAP" == "" ]; then
  export I_MPI_HYDRA_BOOTSTRAP=lsf
fi

export I_MPI_HYDRA_BRANCH_COUNT=4
if [ "$I_MPI_HYDRA_BRANCH_COUNT" == "" ]; then
  export I_MPI_HYDRA_BRANCH_COUNT=`cat $LSB_DJOB_HOSTFILE | uniq | wc -l`
fi

if [ "$I_MPI_LSF_USE_COLLECTIVE_LAUNCH" == "" ]; then
  export I_MPI_LSF_USE_COLLECTIVE_LAUNCH=1
fi

echo "current directory: ${PWD}"

mpiexec.hydra -l $SHYMPI_DIR/bin/shympi $PARAM_FILE $RUNTIME_OPTS

echo "Job completed at: " `date`

sleep 10

