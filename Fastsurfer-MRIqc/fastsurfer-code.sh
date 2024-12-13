#!/bin/bash
#ingularity build fastsurfer-gpu.sif docker://deepmi/fastsurfer:latest
# Define directories and resources
DATASET_DIR="/90days/uqtshaw/aggregate-bids"
FASTSURFER_OUTPUT_DIR="/90days/uqtshaw/fastsurfer-output"
MRIQC_OUTPUT_DIR="/90days/uqtshaw/mriqc-output"
SINGULARITY_FASTSURFER="/90days/uqtshaw/fastsurfer-gpu.sif"
SINGULARITY_MRIQC="/90days/uqtshaw/mriqc.sif"
fs_license="/90days/uqtshaw/"
# Number of concurrent processes and threads per process
MAX_CONCURRENT=5
THREADS_PER_PERSON=10
MRIQC_THREADS=10

# Function to check if FastSurfer output exists
check_fastsurfer_done() {
    local output_dir=$1
    if [ -f "${output_dir}/mri/orig.mgz" ]; then
        return 0
    else
        return 1
    fi
}

# Function to run FastSurfer for a participant/session
# Function to run FastSurfer for a participant/session
run_fastsurfer() {

    local t1_file=$1
    local output_dir=$2
    local participant=$(basename $(dirname $(dirname ${t1_file}))) # Extracts sub-???
    local session=$(basename $(dirname ${t1_file}))               # Extracts ses-???
    local sid="${participant}_${session}"
    echo "Running FastSurfer on ${t1_file}..."
    singularity exec \
        --no-home \
        -B ${fs_license}:/opt/freesurfer \
        -B /90days/uqtshaw/aggregate-bids:/data \
        -B /90days/uqtshaw/my_fastsurfer_analysis:/output \
        "${SINGULARITY_FASTSURFER}" \
        /fastsurfer/run_fastsurfer.sh \
        --fs_license /opt/freesurfer/license.txt \
        --t1 "${t1_file}" \
        --sid ${sid}  \
        --sd "${output_dir}" \
        --parallel \
        --threads "${THREADS_PER_PERSON}"

}

# Function to run MRI QC for a participant/session
run_mriqc() {
    local bids_dir=$1
    local output_dir=$2
    local participant_label=$3
    echo "Running MRI QC for ${participant_label}..."
    singularity exec "${SINGULARITY_MRIQC}" \
        mriqc "${bids_dir}" "${output_dir}" participant \
        --participant-label "${participant_label}" -m T1w --nprocs "${MRIQC_THREADS}"
}

# Create a named pipe for concurrency management
mkfifo pipe
exec 3<> pipe
rm pipe

# Fill the pipe with tokens
for ((i = 0; i < MAX_CONCURRENT; i++)); do
    echo >&3
done

# Process each participant/session
for participant_dir in ${DATASET_DIR}/sub-* ; do
    if [ ! -d "${participant_dir}" ]; then
        echo "Found participant directory: ${participant_dir}"

        continue
    fi

    participant_id=$(basename "${participant_dir}")
    for session_dir in ${participant_dir}/ses-* ; do
        if [ ! -d "${session_dir}" ]; then
        echo "Found sess directory: ${session_dir}"
            continue
        fi

        session_id=$(basename "${session_dir}")
        input_dir="${session_dir}/anat"
        output_fastsurfer="${FASTSURFER_OUTPUT_DIR}/${participant_id}/${session_id}"
        output_mriqc="${MRIQC_OUTPUT_DIR}"

        # Find T1w file
        t1_file=$(find "${input_dir}" -name "*_T1w.nii.gz" | head -n 1)
        if [ -z "${t1_file}" ]; then
            echo "No T1w file found for ${participant_id} ${session_id}. Skipping."
            continue
        fi

        # Wait for a token from the pipe
        read -u 3

        # Process in the background
        {
            # Check and run FastSurfer
            if check_fastsurfer_done "${output_fastsurfer}"; then
                echo "FastSurfer already completed for ${participant_id} ${session_id}. Skipping."
            else
                run_fastsurfer "${t1_file}" "${output_fastsurfer}"
            fi

            # Run MRI QC
            run_mriqc "${DATASET_DIR}" "${output_mriqc}" "${participant_id}"

            # Return a token to the pipe
            echo >&3
        } &
    done
done

# Wait for all processes to finish
wait

# Close the pipe
exec 3>&-
echo "All participants processed."