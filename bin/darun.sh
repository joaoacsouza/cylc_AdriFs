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
## 1.1 NAMELIST
    
    
## 1.2 Submit script
    sed -i "/OV_/c#BSUB -J OV_0" ${ocvar_dir}tmp/aig0/Job_EXP_A1                         ## BSUB -J
    sed -i "/done(adrifs_/c#BSUB -w "done\(adrifs_0\)"" ${ocvar_dir}tmp/aig0/Job_EXP_A1                      ## BSUB -w
    sed -i "/ACTUALINDEX=/cACTUALINDEX=0" ${ocvar_dir}tmp/aig0/Job_EXP_A1                                    ## ACTUALINDEX
    sed -i "/TSD=/cTSD=$start_date" ${ocvar_dir}tmp/aig0/Job_EXP_A1                                             ## TSD
    sed -i "/TED=/cTED=$start_date_next" ${ocvar_dir}tmp/aig0/Job_EXP_A1                                             ## TED
    sed -i "/output_chunk_/cOUTDIR=${ocvar_dir}output/output_chunk_0000" ${ocvar_dir}tmp/aig0/Job_EXP_A1     ## OUTPUT DIR
    
    start_date=$start_date_next

# Submit OceanVar
job_submission_output=$(bsub < submit_oceanvar.sh)

job_id=$(echo "$job_submission_output" | grep -o 'Job <[0-9]*>' | grep -o '[0-9]*')

# Check if job ID was retrieved successfully
if [[ -z "$job_id" ]]; then
    echo "Failed to submit job or capture job ID. Submission output:"
    echo "$job_submission_output"
    exit 1
fi

echo "Job $job_id submitted successfully."

# Function to check job status
check_job_status() {
    bjobs -noheader -o "stat" "$job_id" 2>/dev/null
}

# Wait for the job to complete
while true; do
    status=$(check_job_status)
    if [[ "$status" == "" ]]; then
        echo "Job $job_id not found. Retrying..."
        sleep 30  # Wait before retrying to handle any delay in job status update
        continue
    elif [[ "$status" == "DONE" ]]; then
        echo "Job $job_id completed successfully."
        exit 0
    elif [[ "$status" == "EXIT" ]]; then
        echo "Job $job_id failed."
        exit 1
    else
        echo "Job $job_id is still running (status: $status). Waiting..."
        sleep 60  # Wait for a minute before checking again
    fi
done