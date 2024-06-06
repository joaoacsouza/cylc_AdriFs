#!/bin/bash
echo "Preparing model inputs for cycle point $START_DATE" #$CYLC_TASK_CYCLE_POINT"

# Update date in the pre-processing config file
CYCLE_POINT=$START_DATE
DATE_PART=${CYLCE_POINT:0:8}
HOUR_PART=${CYLCE_POINT:9:2}

#FORMATTED_CYCLE_POINT=$(date -d "${DATE_PART} ${HOUR_PART}:00:00" +"%Y/%m/%d %H:%M:%S")
FORMATTED_CYCLE_POINT=$(date -d "${CYCLE_POINT:0:8} ${CYCLE_POINT:9:2}:00:00" +"%Y/%m/%d %H:%M:%S")
echo $FORMATTED_CYCLE_POINT

# Extract the date and time parts
date_part=$(echo $FORMATTED_CYCLE_POINT| cut -d' ' -f1)
time_part=$(echo $FORMATTED_CYCLE_POINT | cut -d' ' -f2)

# Convert date_part from YYYY/MM/DD to YYYYMMDD
date_part=$(echo $date_part | sed 's/\///g')

# Subtract one day
previous_date=$(date -d "${date_part} -1 day" +%Y/%m/%d)

# Combine the previous date with the time part
previous_datetime="${previous_date} ${time_part}"

echo $previous_datetime

# Extract environment variables
WORKFLOW_ID=${CYLC_WORKFLOW_ID}
TASK_CYCLE_POINT=${CYLC_TASK_CYCLE_POINT}
TASK_NAME=${CYLC_TASK_NAME}
SUITE_WORK_DIR=${CYLC_SUITE_WORK_DIR}

# Construct the execution path
EXECUTION_PATH="${SUITE_WORK_DIR}/${TASK_CYCLE_POINT}/${TASK_NAME}"

# Output the execution path (To  make sure we are in the right place and paths look OK)
echo "SUITE WORK DIR: ${SUITE_WORK_DIR}"
echo "WORKFLOW ID: ${WORKFLOW_ID}"
echo "TASK NAME: ${TASK_NAME}"

echo "Execution Path: ${EXECUTION_PATH}"

# Go to execution directory
cd "${SUITE_WORK_DIR}/../bin"
echo "current directory: ${PWD}"

#### Do the work ######################################################
# Update config file
export yaml_file=${WALUIGI_INPUT_FILE}
export name_to_update="start_date"
export new_value=${previous_datetime}

python update_yaml.py

# Run waluigi
job_submission_output=$(bsub < run_waluigi.sh)

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
