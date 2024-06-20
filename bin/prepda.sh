#!/bin/bash
echo "Submitting OceanVAR run for cycle $START_DATE" #$CYLC_TASK_CYCLE_POINT"

# Update date in the pre-processing config file
CYCLE_POINT=$START_DATE
DATE_PART=${CYLCE_POINT:0:8}
HOUR_PART=${CYLCE_POINT:9:2}

#FORMATTED_CYCLE_POINT=$(date -d "${DATE_PART} ${HOUR_PART}:00:00" +"%Y/%m/%d %H:%M:%S")
FORMATTED_CYCLE_POINT=$(date -d "${CYCLE_POINT:0:8} ${CYCLE_POINT:9:2}:00:00" +"%Y%m%d")
echo $FORMATTED_CYCLE_POINT

# Manipulate start date
date_part=$(echo $FORMATTED_CYCLE_POINT| cut -d' ' -f1)
time_part=$(echo $FORMATTED_CYCLE_POINT | cut -d' ' -f2)

# Convert date_part from YYYY/MM/DD to YYYYMMDD
start_date=$(echo $date_part)

# Subtract one day
start_date_next=$(date -d "${date_part} +1 day" +%Y%m%d)

# Extract environment variables
WORKFLOW_ID=${CYLC_WORKFLOW_ID}
TASK_CYCLE_POINT=${CYLC_TASK_CYCLE_POINT}
TASK_NAME=${CYLC_TASK_NAME}
SUITE_WORK_DIR=${CYLC_SUITE_WORK_DIR}

# Construct the execution path
EXECUTION_PATH="${SUITE_WORK_DIR}/${TASK_CYCLE_POINT}/${TASK_NAME}"

# Go to execution directory
cd "${SUITE_WORK_DIR}/../bin"

##### Do the work ##############################################################
# Subset observations to model domain
python get_sla.py # Get sea level anomaly observations
python get_insitu.py # Get in-situ observations from CMEMS
python get_sst.py # Get satellite SST observations

##### Update OceanVar namelist

# Set the key to update and the new value
key_to_update="RST_DIR_READ="
new_value="${SUITE_WORK_DIR}/../output/shyfem"

# Use sed to update the var_3d_nml file (model namefile)
sed -i.bak "s/^$key_to_update/$key_to_update $new_value/" var_3d_nml

# Set the key to update and the new value
key_to_update="RST_DIR_WRITE="
new_value="${SUITE_WORK_DIR}/../output/OceanVar"

# Use sed to update the var_3d_nml file (model namefile)
sed -i.bak "s/^$key_to_update/$key_to_update $new_value/" var_3d_nml

sed -i '/EXP_NAME=/c\  EXP_NAME='AdriFs_',' var_3d_nml

# Update OceanVar run script
sed -i "/OV_/c#BSUB -J OV_$i" submit_oceanvar.sh                            ## BSUB -J
sed -i "/done(adrifs_/c#BSUB -w 'done\(adrifs_$i\)'" submit_oceanvar.sh                         ## BSUB -w
sed -i "/ACTUALINDEX=/cACTUALINDEX=$i" submit_oceanvar.sh                                       ## ACTUALINDEX
sed -i "/TSD=/cTSD=$start_date" submit_oceanvar.sh                                                 ## TSD
sed -i "/TED=/cTED=$start_date_next" submit_oceanvar.sh                                                 ## TED

