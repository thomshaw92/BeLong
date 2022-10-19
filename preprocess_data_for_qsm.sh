#!/bin/bash

#THIS SCRIPT HAS TO BE RUN FROM THE SAME PLACE AS INPUT

# Process data. This script is designed to be run in the folder for a single subject, however 'sct_run_batch' can be
# used to run this script multiple times in parallel across a multi-subject BIDS dataset.

#
# Usage:
#   ./process_data.sh <SUBJECT>
#
# Example:
#   ./process_data.sh sub-03
#
# Author: Julien Cohen-Adad - include dMRI, T1w, T2Star and updates by Thomas Shaw 20220420

# The following global variables are retrieved from the caller sct_run_batch
# but could be overwritten by uncommenting the lines below:
PATH_DATA_PROCESSED="/90days/uqtshaw/BeLong/BeLong_SCT_BIDS/data_processed"
PATH_RESULTS="/90days/uqtshaw/BeLong/BeLong_SCT_BIDS/results"
PATH_LOG="/90days/uqtshaw/BeLong/BeLong_SCT_BIDS/log"
PATH_QC="/90days/uqtshaw/BeLong/BeLong_SCT_BIDS/qc"

# BASH SETTINGS

# ======================================================================================================================
# Uncomment for full verbose
# set -v
# Immediately exit if error
set -e
# Exit if user presses CTRL+C (Linux) or CMD+C (OSX)
trap "echo Caught Keyboard Interrupt within script. Exiting now.; exit" INT
# CONVENIENCE FUNCTIONS

# ======================================================================================================================
label_if_does_not_exist() {
    ###
    #  This function checks if a manual label file already exists, then:
    #     - If it does, copy it locally.
    #     - If it doesn't, perform automatic labeling.
    #   This allows you to add manual labels on a subject-by-subject basis without disrupting the pipeline.
    ###
    local file="$1"
    local file_seg="$2"
    # Update global variable with segmentation file name
    FILELABEL="${file}_labels.nii.gz"
    FILELABELMANUAL="${PATH_DATA}/derivatives/labels/${SUBJECT}/anat/${FILELABEL}-manual.nii.gz"
    echo "Looking for manual label: $FILELABELMANUAL"
    if [[ -e $FILELABEL ]]; then
	echo "Found! Using manualalready generated labels."
	#rsync -avzh "$FILELABELMANUAL" "${FILELABEL}".nii.gz
    else
	echo "Not found. Proceeding with automatic labeling."
	# Generate labeled segmentation
	sct_label_vertebrae -i "${file}".nii.gz -s "${file_seg}" -c t2 -qc "${PATH_QC}" -qc-subject "${SUBJECT}"
	# Create labels in the cord at C3 and C5 mid-vertebral levels
	sct_label_utils -i "${file_seg:0:-7}"_labeled.nii.gz -vert-body 3,5 -o "${FILELABEL}"
    fi
}

segment_if_does_not_exist() {
    ###
    #  This function checks if a manual spinal cord segmentation file already exists, then:
    #    - If it does, copy it locally.
    #    - If it doesn't, perform automatic spinal cord segmentation.
    #  This allows you to add manual segmentations on a subject-by-subject basis without disrupting the pipeline.
    ###
    local file="$1"
    local contrast="$2"
    # Update global variable with segmentation file name
    ####NOTE I changed this because it sucked
    FILESEG="${file}_seg".nii.gz
    FILESEGMANUAL="${PATH_DATA}/derivatives/labels/${SUBJECT}/anat/${FILESEG}-manual.nii.gz"
    echo
    echo "Looking for any segmentation: $FILESEG"
    if [[ -e $FILESEG ]]; then
	echo "Found! Using manual segmentation."
	#rsync -avzh "$FILESEGMANUAL" "${FILESEG}".nii.gz
	sct_qc -i "${file}".nii.gz -s "${FILESEG}" -p sct_deepseg_sc -qc ${PATH_QC} -qc-subject "${SUBJECT}"
    else
	echo "Not found. Proceeding with automatic segmentation."
	# Segment spinal cord
	sct_deepseg_sc -i "${file}".nii.gz -c "$contrast" -qc ${PATH_QC} -qc-subject "${SUBJECT}"
    fi
}

# SCRIPT STARTS HERE
# ======================================================================================================================
# Retrieve input params
SUBJECT=${1}
ses="ses-01"
# get starting time:
start=$(date +%s)

# Display useful info for the log, such as SCT version, RAM and CPU cores available
sct_check_dependencies -short

# Go to folder where data will be copied and processed
cd $PATH_DATA_PROCESSED
# Copy source images
rsync -avzh "$PATH_DATA"/"${SUBJECT}" .
echo subjname
echo ${SUBJECT}
echo path of data processed
echo $PATH_DATA_PROCESSED
echo path of data??
echo $PATH_DATA
module load ants/2.3.5
# T2w Segmentation and CSA
# ======================================================================================================================
cd "${SUBJECT}/anat/"

#QSM_spinal_cord.
# ===========================================================================================
cd ../qsm/
file_qsm_head_m="qsmHM"
file_qsm_head_p="qsmH"
file_qsm_neck_m="qsmNM"
file_qsm_neck_p="qsmN"

#first resample 
sct_resample -i ${file_qsm_neck_p}.nii.gz -mm 0.5x0.5x0.5 -x spline -o ${file_qsm_neck_p}_resampled.nii.gz
sct_resample -i ${file_qsm_neck_m}.nii.gz -mm 0.5x0.5x0.5 -x spline -o ${file_qsm_neck_m}_resampled.nii.gz

#crop the mag and phase images in head to be the same as neck size and shape
sct_register_multimodal -i ${file_qsm_head_p}.nii.gz -d ${file_qsm_neck_p}_resampled.nii.gz -identity 1 -o ${file_qsm_head_p}_resampled.nii.gz 
sct_register_multimodal -i ${file_qsm_head_m}.nii.gz -d ${file_qsm_neck_m}_resampled.nii.gz -identity 1 -o ${file_qsm_head_m}_resampled.nii.gz


# Segment SC on mag images
sct_deepseg_sc -i ${file_qsm_neck_m}_resampled.nii.gz \
	       -c t2s \
	       -qc "${PATH_QC}"

#reg head and neck images to same space (neck space as we use t2s later)
sct_register_multimodal -i ${file_qsm_head_m}_resampled.nii.gz -d ${file_qsm_neck_m}_resampled.nii.gz \
			-param step=1,type=im,algo=rigid,slicewise=1,metric=CC \
			-x spline -qc "${PATH_QC}" -owarp ${file_qsm_head_m}_crop_to_${file_qsm_neck_m}_warp.nii.gz
#warp head to neck
sct_apply_transfo -i ${file_qsm_head_p}_resampled.nii.gz -d ${file_qsm_neck_p}_resampled.nii.gz \
		  -w ${file_qsm_head_m}_crop_to_${file_qsm_neck_m}_warp.nii.gz \
		  -o head_qsm_to_neckqsm.nii.gz -x spline
#n = neck
#h = head and neck
#m = magnitude, p = phase (qsm output processed image from QSMxT)
sct_create_mask -i ${file_qsm_head_m}.nii.gz -p centerline,./${file_qsm_seg} -size 35mm -f cylinder -o mask_qsm_hm.nii.gz
sct_create_mask -i ${file_qsm_head_p}.nii.gz -p centerline,./${file_qsm_seg} -size 35mm -f cylinder -o mask_qsm_hp.nii.gz
sct_create_mask -i ${file_qsm_neck_m}.nii.gz -p centerline,./${file_qsm_seg} -size 35mm -f cylinder -o mask_qsm_nm.nii.gz
sct_create_mask -i ${file_qsm_neck_p}.nii.gz -p centerline,./${file_qsm_seg} -size 35mm -f cylinder -o mask_qsm_np.nii.gz
#crop
sct_crop_image -i ${file_qsm_head_m}.nii.gz -m mask_qsm_hm.nii.gz
sct_crop_image -i ${file_qsm_head_p}.nii.gz -m mask_qsm_hp.nii.gz
sct_crop_image -i ${file_qsm_neck_m}.nii.gz -m mask_qsm_nm.nii.gz
sct_crop_image -i ${file_qsm_neck_p}.nii.gz -m mask_qsm_np.nii.gz
done

# Display useful info for the log
end=$(date +%s)
runtime=$((end-start))
echo
echo "~~~"
echo "SCT version: $(sct_version)"
echo "Ran on:      $(uname -nsr)"
echo "Duration:    $(($runtime / 3600))hrs $((($runtime / 60) % 60))min $(($runtime % 60))sec"
echo "~~~"
