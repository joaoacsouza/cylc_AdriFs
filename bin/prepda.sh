#!/bin/bash
echo "Submitting OceanVAR run for cycle $START_DATE" #$CYLC_TASK_CYCLE_POINT"

# Update date in the pre-processing config file
CYCLE_POINT=$START_DATE
DATE_PART=${CYLCE_POINT:0:8}
HOUR_PART=${CYLCE_POINT:9:2}

#FORMATTED_CYCLE_POINT=$(date -d "${DATE_PART} ${HOUR_PART}:00:00" +"%Y/%m/%d %H:%M:%S")
FORMATTED_CYCLE_POINT=$(date -d "${CYCLE_POINT:0:8} ${CYCLE_POINT:9:2}:00:00" +"%Y%m%d")
echo $FORMATTED_CYCLE_POINT

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
#python get_sst.py # Get satellite SST observations