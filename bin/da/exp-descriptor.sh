# TIPS for a long run
#  {phys/wave}_rst
#  timing_hours
#  RR_interval=L
#  ServiceClass* if any
# Dealing with assimilation :
#  assim_rst
#  first day : TDVARFromSimu=yes ; then TDVARFromSimu=no
# Dealing with hourly output :
#  EXP_LF=csf_assw_hourly_pp.txt

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# GENERAL : attachments for experiment definition
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

EXP_LF=csf_assm.txt

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# GENERAL : timing (NEMO still needs specific paramenters)
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

timing_start_from_restart=file    #now works only with NEMO
                                  #possible value are "none" or "file"
                                  #complete path to a NEMO restart file
#if timing_start_from_restart=file , to set :
#wave_rst=/work/opa/mfs-dev/exp/eas6_v2/mfs1/output/restart1.ww3_2019010100
phys_rst=/data/oda/aa32919/med-input/restart/restart.nc_2018100100_OT
assim_rst=/data/oda/aa32919/med-input/restart/ANINCR.NC.2018100100_OT
#assim_rst=${MYENVDEV_WORKDIR}/exp/${MYENVDEV_ALIAS}/

#if timing_start_from_restart=none , to set :
timing_start_time=${MYE_STARTDATE}
timing_start_hour='00'       

timing_restart_hours=24
timing_hours=2208  #(366*356*365)*24 #TOSET  Oct-Dec 2018
timing_hours=72  #(366*356*365)*24 #TOSET  Oct-Dec 2018


#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# NEW FLAGS to be set
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

RR_interval=F          # Ignored if ProductionMode=operational and ! TDVAR=yes
                       # Set the interval to rebuild the output restart, in days
                       #          or
                       #          0=no action
                       #          1=all output restart
                       #          L=last of month
                       #          F=first day of month
export output_sort=yes # Move output file in YYYYMM folders

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# GENERAL : working directory
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if [ -z $MYENVDEV_ALIAS ] ; then echo MYENVDEV_ALIAS not defined - exit ; exit 1; fi
ScratchDir=${MYENVDEV_WORKDIR}/exp/$MYENVDEV_ALIAS #DO NOT CHANGE

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# RM : type of resource management 
#  with JobType="torque"   -> torque/qsub
#  with JobType="bash"     -> just run the scripts
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#LSF_ServiceClass=                 #optional parameter
#LSF_ServiceClass=${MYE_SC}         #long and urgent

LSF_PP_JobType="lsf-zeus-nx"
#LSF_PP_ServiceClass=              #optional parameter
#LSF_PP_ServiceClass=${MYE_SC_serial}  #long and urgent
LSF_PP_WallTime=30                 #optional parameter

LSF_OM_JobType="lsf-zeus-x"
#LSF_OM_WallTime=60                #optional parameter
                                   #you can change this during the run

LSF_Project=${MYE_LSF_Project}
#LSF_PAPP=${MYE_LSF_PAPP}
#LSF_SAPP=${MYE_LSF_SAPP}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# RM : name of queues 
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

QueueNameP=$MYE_QUEUEP               #you can change this during the run
QueueNameS=$MYE_QUEUES               #you can change this during the run

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# SYS : system name 
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

export ProductionMode=timeseries
#export ProductionMode=operational
#ProductionCycle=YYYYMMDD

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# NEMO 
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

NEMO=yes

NEMOTimestep=120

SSTActive=yes
#SSTActive=no
export SST_DATA0=$MYE_SSTDATA0

NEMO_NL=phys/namelist_1.assm

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# NEMO : Set number of compulational processes
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#In attached mode :
nemo_n_mpi_proc=252

#In detached mode :
#export PETRA_EXE_STYLE='nemodetached'
#nemo_n_mpi_proc=129 # = 128 + number of i/o process
#NemoIoModule=129

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# NEMO : data
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

NEMO_DATA0=$MYE_NEMO_DATA0                #EXT_DEPENDENCY
NEMO_DATA1=$MYE_NEMO_DATA1                #EXT_DEPENDENCY
NEMO_DATA2=${NEMO_DATA1}/                      #DO NOT CHANGE
                                               #mode=timeseries : it is the repository with dir LOBC and free structure
                                               #mode=operational : it is the repository with dir LOBC/YYYYMMDD

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 3DVAR
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

TDVAR=yes
#TDVAR=no
INSITUActive=$TDVAR   # to remove
TDVARFromSimu=yes
#TDVARFromSimu=no

LSF_OA_JobType="lsf-zeus-assim_mpi"
#LSF_OA_WallTime=                   #optional parameter
                                    #you can change this during the run
tdvar_n_omp_proc=18
tdvar_n_mpi_proc=15

export TDVAR_DATA0=$MYE_TDVAR_DATA0
#export TDVAR_IndataFrom="upstream"                          #data from upstream -> needs TDVAR_DATA1
export TDVAR_IndataFrom="preproc"                          #mannual preproc    -> needs TDVAR_DATA2
#TDVAR_DATA1=$MYE_TDVAR_DATA1                           #data from upstream
TDVAR_DATA2=$MYE_TDVAR_DATA2                          #pre-processed data 

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# WW
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

WW=no
ww_n_mpi_proc=128
WW_DATAIN=$MYE_WW_DATA0   #EXT_DEPENDENCY
 
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# END
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

