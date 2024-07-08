#!/bin/ksh

#Da ExpBuild
#WORKINGDIR
#TED

#Usati anche
#TDVAR_DATA0
#nemo_n_mpi_proc
#TDVAR_DATA1

set -vx

WORKINGDIR=$1
TED=$2
TDVAR_DATA0=$3
nemo_n_mpi_proc=$4
TDVAR_DATA1=$5

sec_counter.py TagSecCounterAB_rebiuld_done

exe=../var_3d
#sh_exe=../shuffle_obs.x
nam=../var_3d_nml

cp /users_home/cmcc/js04724/source/OceanVar/bin/var_3d_juno_mpi.x $exe
#cp /users_home/cmcc/js04724/source/OceanVar/shuffle_obs/shuffle_obs.x $sh_exe

# Nominal Date/time of analysis
ymdh=${TED}00
# Date manipulation
ymd=`echo $ymdh | cut -c 1-8`
hh=`echo $ymdh | cut -c 9-10`
mm=`echo $ymd | cut -c 5-6`
# Assimilation time-window (in days)
ass_tw=1
# Configuration of 3DVAR
# 101 : Complete 3dvar reading NEMO background
# 102 : Only prepare obs for NEMO misfits computation
# 103 : 3dvar reading misfits only

# Input files that will be linked in the workdir
#set -A infiles GRID.nc \
#lha_err.dat sal_clim.nc \
#tem_clim.nc mdt_med_20y_124.nc

#DATA0=$TDVAR_DATA0
# Directory with 3DVAR static inputs for Med Sea
datadir=${TDVAR_DATA0}/STATIC_3DVAR_24
# Insitu Observation directories
#coradir=${TDVAR_DATA1}/CORA
# TYPE_INS: 1= UKMO EN; 2= CORA/CMEMS
#TYPE_INS=2
# namelist
nam=./var_3d_nml
# SLA data: directory, list of satellites
#msdir=${TDVAR_DATA1}/OBS/SLA/nrt_along-track
#nsat=4
#set -A snam ALTIKA CRYOSAT2 JASON1 JASON2
#set -A snic     al       c2  j1g     j2

# EOF directory
eofdir=${TDVAR_DATA0}/STATIC_3DVAR_24
eofprf=EOF_M

# Linking static files for 3dvar
nf=${#infiles[*]}
if=0
while [ $if -lt $nf ]; do
	fi=$datadir/${infiles[$if]}
	ln -sf $fi .
	if=$(( $if + 1 ))
done

#ln -sf GRID.nc GRID_BS.nc
#ln -sf sani*.nos BACKGROUND.nc

#ln -sf ../tmp/domains.dat

#$sh_exe $nproc || exit -5
#$sh_exe || exit -5

# Linking Correlation length-scales with appropriate filenames
#ln -sf CORRAD.nc Corrad_onx.nc
#ln -sf CORRAD.nc Corrad_ony.nc
#link the appropriate MDT
#ln -fs $datadir/mdt_med_20y_124.nc MDT.nc

# Namelist
##ln -sf $nam var_3d_nml

# Fetch representativeness error files
#ln -sf $datadir/SLA_repres_$mm.nc SLA_repres.nc
#ln -sf $datadir/SST_repres_$mm.nc SST_repres.nc

# Fetch EOFs
ln -sf $eofdir/$eofprf${mm}.nc EOF.nc

# Fetch INSITU_ERRORS files (added by elisa)
#ln -sf $datadir/insitu_errors_M${mm}.nc insitu_errors.nc

# Link the mpp_conf.dat
#ln -fs ../tmp/mpp_conf.dat mpp_conf.dat

#sec_counter.py TagSecCounterAC_prep_done

# Copy and run the 3DVAR executable
# "-c 0" means the assimilation window ends in ymd:
# this is typical for real-time applications

# if "-c" not specified or "-c 1" tha assimilation window
# is centered in ymd: this is typical for reanalysis applications
ln -s $exe MASTER
time mpiexec.hydra -l ./MASTER -d ${ymd} -t ${hh}00 -w $(( $ass_tw * 24 )) -c 0 > \
  3DVAR.out 2>&1 || \
  { echo "3DVAR returned non-zero status, aborting!" ; exit 12 ; }

#sec_counter.py TagSecCounterAD_parallel_done

#for f in ANINCR.NC OBSSTAT.NC LOG_3DVAR COST.DAT OBSSTAT_SCREEN.NC; do
#  mv $f $WORKINGDIR/output/${f}.${ymdh}
#done

# The main output to archive/use and look at are

# 1) LOG_3DVAR : logfile (quite verbose)
# 2) ANINCR.NC : analysis increments (to be used by NEMO)
# 3) COST.DAT  : cost function diagnostics
# 4) OBSSTAT*NC: observation diagnostics

#sec_counter.py TagSecCounterAE_post_done
