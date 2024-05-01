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
PATH_DATA_PROCESSED="/Volumes/BeLong/BeLong/BeLong_SCT_BIDS/data_processed"
PATH_RESULTS="/Volumes/BeLong/BeLong/BeLong_SCT_BIDS/data_processed/results"
PATH_LOG="/Volumes/BeLong/BeLong/BeLong_SCT_BIDS/data_processed/log"
PATH_QC="/Volumes/BeLong/BeLong/BeLong_SCT_BIDS/data_processed/qc"
# BASH SETTINGS

# ======================================================================================================================
# Uncomment for full verbose
# set -v
# Immediately exit if error
#set -e
# Exit if user presses CTRL+C (Linux) or CMD+C (OSX)
trap "echo Caught Keyboard Interrupt within script. Exiting now.; exit" INT


# SCRIPT STARTS HERE
# ======================================================================================================================
# Retrieve input params
SUBJECT=${1}

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

if [[ -z "$SCT_BP_QC_FOLDER" ]]; then
	SCT_BP_QC_FOLDER="/Volumes/BeLong/BeLong/BeLong_SCT_BIDS/data_processed/qc"
fi

# T2w Segmentation and CSA
# ======================================================================================================================
cd "${SUBJECT}/anat/"
file_t2="${SUBJECT}_run-1_T2w"
sct_deepseg_sc -i ${file_t2}.nii.gz -c t2 -qc "$SCT_BP_QC_FOLDER"
# Tips: If you are not satisfied with the results you can try with another algorithm:
# sct_propseg -i ${file_t2}.nii.gz -c t2 -qc "$SCT_BP_QC_FOLDER"
# Fit binarized centerline from SC seg (default settings)
sct_get_centerline -i ${file_t2}_seg.nii.gz \
	-method fitseg -qc "$SCT_BP_QC_FOLDER"
# Fit soft centerline from SC seg
sct_get_centerline -i ${file_t2}_seg.nii.gz \
	-method fitseg -centerline-soft 1 -o ${file_t2}_seg_centerline_soft.nii.gz -qc "$SCT_BP_QC_FOLDER"
# Vertebral labeling

if [[ ! -e "${file_t2}_label_c2c3.nii.gz" ]]; then
	sct_label_utils -i ${file_t2}.nii.gz -create-viewer 3 -o ${file_t2}_label_c2c3.nii.gz \
				-msg "Click at the posterior tip of C2/C3 inter-vertebral disc"
fi

# Tips: for manual initialization of labeling by clicking at disc C2-C3, use flag -initc2
sct_label_vertebrae -i ${file_t2}.nii.gz -s ${file_t2}_seg.nii.gz -initlabel ${file_t2}_label_c2c3.nii.gz -c t2 -qc "$SCT_BP_QC_FOLDER"
# Create labels at in the cord at C2 and C5 mid-vertebral levels
sct_label_utils -i ${file_t2}_seg_labeled.nii.gz -vert-body 2,5 -o labels_vert.nii.gz
# Tips: you can also create labels manually using:
# sct_label_utils -i ${file_t2}.nii.gz -create-viewer 2,5 -o labels_vert.nii.gz
# Register to template
sct_register_to_template -i ${file_t2}.nii.gz -s ${file_t2}_seg.nii.gz \
	-l labels_vert.nii.gz -c t2 -qc "$SCT_BP_QC_FOLDER"
# Tips: If you are not satisfied with the results, you can tweak registration parameters.
# For example here, we would like to take into account the rotation of the cord, as well as
# adding a 3rd registration step that uses the image intensity (not only cord segmentations).
# so we could do something like this:
#sct_register_multimodal -i "$SCT_DIR/data/PAM50/template/PAM50_t2s.nii.gz" \
#	-iseg "$SCT_DIR/data/PAM50/template/PAM50_cord.nii.gz" \
#	-d ${file_t2s}.nii.gz \
#	-dseg ${file_t2s}_seg.nii.gz \
#	-param step=1,type=seg,algo=slicereg,smooth=3:step=2,type=seg,algo=bsplinesyn,slicewise=1,iter=3 \
#	-initwarp ../anat/warp_template2anat.nii.gz
# Warp template without the white matter atlas (we don't need it at this point)
sct_warp_template -d ${file_t2}.nii.gz -w warp_template2anat.nii.gz -a 0
# Compute cross-sectional area (and other morphometry measures) for each slice
sct_process_segmentation -i ${file_t2}_seg.nii.gz 
# Compute cross-sectional area and average between C2 and C3 levels
sct_process_segmentation -i ${file_t2}_seg.nii.gz -vert 2:3 -o ${PATH_RESULTS}/csa_c2c3.csv -append 1
# Compute cross-sectionnal area based on distance from pontomedullary junction (PMJ)
# Detect PMJ
sct_detect_pmj -i ${file_t2}.nii.gz -c t2 -qc "$SCT_BP_QC_FOLDER" 
# Compute cross-section area at 60 mm from PMJ averaged on a 30 mm extent
sct_process_segmentation -i ${file_t2}_seg.nii.gz \
	-pmj ${file_t2}_pmj.nii.gz -pmj-distance 60 -pmj-extent 30 -qc "$SCT_BP_QC_FOLDER" \
	-qc-image ${file_t2}.nii.gz \
	-o ${PATH_RESULTS}/csa_pmj.csv -append 1
# Compute morphometrics in PAM50 anatomical dimensions
sct_process_segmentation -i ${file_t2}_seg.nii.gz -vertfile ${file_t2}_seg_labeled.nii.gz \
	-perslice 1 -normalize-PAM50 1 -o ${PATH_RESULTS}/csa_pam50.csv -append 1 \
	-qc "$SCT_BP_QC_FOLDER"



# ======================================================================================================================
#T2 Star (ME-GRE)
file_t2s="${SUBJECT}_run-1_T2starw"

# Spinal cord segmentation
sct_deepseg_sc -i ${file_t2s}.nii.gz -c t2s -qc "$SCT_BP_QC_FOLDER"
# Segment gray matter
sct_deepseg_gm -i ${file_t2s}.nii.gz -qc "$SCT_BP_QC_FOLDER"
# Register template->t2s (using warping field generated from template<->t2 registration)
sct_register_multimodal -i "${SCT_DIR}/data/PAM50/template/PAM50_t2s.nii.gz" \
	-iseg "${SCT_DIR}/data/PAM50/template/PAM50_cord.nii.gz" \
	-d "${file_t2s}.nii.gz" -dseg "${file_t2s}_seg.nii.gz" \
	-param step=1,type=seg,algo=centermass:step=2,type=seg,algo=bsplinesyn,slicewise=1,iter=3:step=3,type=im,algo=syn,slicewise=1,iter=1,metric=CC \
	-initwarp warp_template2anat.nii.gz \
	-initwarpinv warp_anat2template.nii.gz \
	-owarp warp_template2${file_t2s}.nii.gz \
	-owarpinv warp_t2s2template.nii.gz
# Warp template
sct_warp_template -d ${file_t2s}.nii.gz -w "warp_template2${file_t2s}.nii.gz"
# Subtract GM segmentation from cord segmentation to obtain WM segmentation
sct_maths -i ${file_t2s}_seg.nii.gz -sub ${file_t2s}_gmseg.nii.gz -o ${file_t2s}_wmseg.nii.gz
# Compute cross-sectional area of the gray and white matter between C2 and C5
sct_process_segmentation -i ${file_t2s}_wmseg.nii.gz -vert 2:5 -perlevel 1 \
	-o ${PATH_RESULTS}/csa_wm.csv -append 1 \
	-angle-corr-centerline ${file_t2s}_seg.nii.gz
sct_process_segmentation -i ${file_t2s}_gmseg.nii.gz -vert 2:5 -perlevel 1 \
	-o ${PATH_RESULTS}/csa_gm.csv -append 1 \
	-angle-corr-centerline ${file_t2s}_seg.nii.gz
# OPTIONAL: Update template registration using information from gray matter segmentation
# # <<<
# # Register WM/GM template to WM/GM seg
sct_register_multimodal -i "$SCT_DIR/data/PAM50/template/PAM50_wm.nii.gz" \
	-d ${file_t2s}_wmseg.nii.gz -dseg ${file_t2s}_seg.nii.gz \
	-param step=1,type=im,algo=syn,slicewise=1,iter=5 \
	-initwarp warp_template2${file_t2s}.nii.gz \
	-initwarpinv warp_t2s2template.nii.gz \
	-qc "$SCT_BP_QC_FOLDER" -owarp warp_template2${file_t2s}.nii.gz \
	-owarpinv warp_t2s2template.nii.gz
# # Warp template (this time corrected for internal structure)
sct_warp_template -d ${file_t2s}.nii.gz -w warp_template2${file_t2s}.nii.gz
# # >>>

#QSM_spinal_cord.
# ===========================================================================================
#cd ../qsm/
#file_qsm_head_m="qsmHM"
#file_qsm_head_p="qsmH"
#file_qsm_neck_m="qsmNM"
#file_qsm_neck_p="qsmN"

#preprocessing of Mag image. - don't need this
#do it this way?
#if [[ ! -e qsmHM_seg.nii.gz ]] ; then
#    sct_deepseg_sc -i qsmHM.nii.gz -c t2s -centerline svm
#else 
#    sct_qc -i "qsmHM.nii.gz" -s qsmHM_seg.nii.gz -p sct_deepseg_sc -qc ${PATH_QC} -qc-subject "${SUBJECT}"
#fi
#you need to move the SIEMENS Magnitude not the ASPIRE coil comb. because the intensity scalings are off
#file_qsm_seg="qsmHM_seg.nii.gz"
# Create labels in the cord at C2 and C5 mid-vertebral levels (only if it does not exist)
#label_if_does_not_exist "${file_qsm_head_m}" "${file_qsm_seg}"
#file_label="${FILELABEL}"
#this might not work or be necessary but worth a shot. 

#bring the Mag into the space of the template for downstream stats. Take the QSM output with it.
#first crop the SC for ease of reg. ##TODO check if naming is correct for t1_seg
#n = neck
#h = head and neck
#m = magnitude, p = phase (qsm output processed image from QSMxT)
#sct_create_mask -i ${file_qsm_head_m}.nii.gz -p centerline,./${file_qsm_seg} -size 35mm -f cylinder -o mask_qsm_hm.nii.gz
#sct_create_mask -i ${file_qsm_head_p}.nii.gz -p centerline,./${file_qsm_seg} -size 35mm -f cylinder -o mask_qsm_hp.nii.gz
#sct_create_mask -i ${file_qsm_neck_m}.nii.gz -p centerline,./${file_qsm_seg} -size 35mm -f cylinder -o mask_qsm_nm.nii.gz
#sct_create_mask -i ${file_qsm_neck_p}.nii.gz -p centerline,./${file_qsm_seg} -size 35mm -f cylinder -o mask_qsm_np.nii.gz
#crop
#sct_crop_image -i ${file_qsm_head_m}.nii.gz -m mask_qsm_hm.nii.gz
#sct_crop_image -i ${file_qsm_head_p}.nii.gz -m mask_qsm_hp.nii.gz
#sct_crop_image -i ${file_qsm_neck_m}.nii.gz -m mask_qsm_nm.nii.gz
#sct_crop_image -i ${file_qsm_neck_p}.nii.gz -m mask_qsm_np.nii.gz

#just crop the whole damn image - ignore everything above
#first resample 
#sct_resample -i ${file_qsm_neck_p}.nii.gz -mm 0.5x0.5x0.5 -x spline -o ${file_qsm_neck_p}_resampled.nii.gz
#sct_resample -i ${file_qsm_neck_m}.nii.gz -mm 0.5x0.5x0.5 -x spline -o ${file_qsm_neck_m}_resampled.nii.gz

#crop the mag and phase images in head to be the same as neck size and shape
#sct_register_multimodal -i ${file_qsm_head_p}.nii -d ${file_qsm_neck_p}.nii -identity 1 -o ${file_qsm_head_p}_resampled.nii 
#sct_register_multimodal -i ${file_qsm_head_m}.nii.gz -d ${file_qsm_neck_m}.nii.gz -identity 1 -o ${file_qsm_head_m}_resampled.nii.gz


# Segment SC on mag images
#sct_deepseg_sc -i ${file_qsm_neck_m}_resampled.nii.gz \
    #	       -c t2s \
    #	       -qc "${PATH_QC}"
#this is done manually now as part of QSM processing, so copy mask over for easy labeling


#################################
## This code needs to be fixed ##
#################################

##cp /Volumes/BeLong/BeLong/BeLong_QSMxT_BIDS/01_qsmxt_niftis_sorted_by_qsmxt_dilated_05/${SUBJECT}/ses-1/extra_data/${SUBJECT}_run-01_mask.nii.gz ./${file_qsm_neck_m}"_resampled_seg.nii.gz"
#
##reg head and neck images to same space (neck space as we use t2s later)
#sct_register_multimodal -i ${file_qsm_head_m}_resampled.nii.gz -d ${file_qsm_neck_m}.nii.gz \
#			-param step=1,type=im,algo=rigid,slicewise=1,metric=CC \
#			-x spline -qc "${PATH_QC}" -owarp ${file_qsm_head_m}_crop_to_${file_qsm_neck_m}_warp.nii.gz
##warp head phase to neck
#sct_apply_transfo -i ${file_qsm_head_p}_resampled.nii -d ${file_qsm_neck_p}.nii \
#		  -w ${file_qsm_head_m}_crop_to_${file_qsm_neck_m}_warp.nii.gz \
#		  -o head_qsm_to_neckqsm.nii -x spline
#
#mkdir -p label_qsm
## Register template->qsm via t2s to account for GM segmentation
##: the flag “-initwarpinv" provides a transformation qsm->template, in case you would like to bring all your qsm
##       metrics in the PAM50 space (e.g. group averaging of maps)
#sct_register_multimodal -i "${SCT_DIR}/data/PAM50/template/PAM50_t1.nii.gz" \
#			-iseg "${SCT_DIR}/data/PAM50/template/PAM50_cord.nii.gz" \
#			-d "${file_qsm_neck_m}"_resampled.nii.gz \
#			-dseg "${file_qsm_neck_m}"_resampled_seg.nii.gz \
#		      	-initwarp ../anat/warp_template2${file_t2s}.nii.gz \
#			-initwarpinv ../anat/warp_t2s2template.nii.gz \
#			-owarp warp_template2qsm.nii.gz \
#			-owarpinv warp_qsm2template.nii.gz \
#			-param step=1,type=seg,algo=centermass:step=2,type=seg,algo=bsplinesyn,slicewise=1,iter=3 \
#			-qc "$PATH_QC"
#
## Warp template to head and neck qsm finals.
#sct_warp_template -d head_qsm_to_neckqsm.nii \
#		  -w ./warp_template2qsm.nii.gz -qc "${PATH_QC}"
#sct_warp_template -d "${file_qsm_neck_p}".nii \
#		  -w ./warp_template2qsm.nii.gz -qc "${PATH_QC}"
#
## compute qsm between C2 and T1 (append across subjects) ##todo - check if the label_qsm is correct
#sct_extract_metric -i ${file_qsm_neck_p}.nii -f label/atlas -vert 2:8 -vertfile label/template/PAM50_levels.nii.gz \
#                   -perlevel 1 -method map -o "${PATH_RESULTS}/QSM_in_labels.csv" -append 1
#sct_extract_metric -i head_qsm_to_neckqsm.nii -f label/atlas -vert 2:8 -vertfile label/template/PAM50_levels.nii.gz \
#                   -perlevel 1 -method map -o "${PATH_RESULTS}/QSM_in_labels.csv" -append 1
#sct_extract_metric -i ${file_qsm_neck_p}.nii -f label/atlas -vert 2:5 -l 51,30,31,34,35 -vertfile label/template/PAM50_levels.nii.gz \
#                   -perlevel 1 -method map -o "${PATH_RESULTS}/WM_and_ventral_dorsal_horn.csv" -append 1
#sct_extract_metric -i head_qsm_to_neckqsm.nii -f label/atlas -vert 2:5 -l 51,30,31,34,35 -vertfile label/template/PAM50_levels.nii.gz \
#                   -perlevel 1 -method map -o "${PATH_RESULTS}/WM_and_ventral_dorsal_horn.csv" -append 1
#
#30, GM left ventral horn, PAM50_atlas_30.nii.gz
#31, GM right ventral horn, PAM50_atlas_31.nii.gz
#32, GM left intermediate zone, PAM50_atlas_32.nii.gz
#33, GM right intermediate zone, PAM50_atlas_33.nii.gz
#34, GM left dorsal horn, PAM50_atlas_34.nii.gz
#35, GM right dorsal horn, PAM50_atlas_35.nii.gz
# MT
# ======================================================================================================================
# Go back to root folder
#cd ../anat
file_mt1="${SUBJECT}_acq-MTon_run-1_MTS"
file_mt0="${SUBJECT}_acq-MToff_run-1_MTS"

# Get centerline from mt1 data
sct_get_centerline -i ${file_mt1}.nii.gz -c t2 -qc "$SCT_BP_QC_FOLDER"
# Create mask
sct_create_mask -i ${file_mt1}.nii.gz -p centerline,${file_mt1}_centerline.nii.gz -size 45mm
# Crop data for faster processing
sct_crop_image -i ${file_mt1}.nii.gz -m mask_${file_mt1}.nii.gz -o ${file_mt1}_crop.nii.gz
# Segment spinal cord
sct_deepseg_sc -i ${file_mt1}_crop.nii.gz -c t2 -qc "$SCT_BP_QC_FOLDER"
# Register mt0->mt1
# Tips: here we only use rigid transformation because both images have very similar sequence parameters. We don't want to use SyN/BSplineSyN to avoid introducing spurious deformations.
# Tips: here we input -dseg because it is needed by the QC report
sct_register_multimodal -i ${file_mt0}.nii.gz -d ${file_mt1}_crop.nii.gz \
	-dseg ${file_mt1}_crop_seg.nii.gz -param step=1,type=im,algo=slicereg,metric=CC \
	-x spline -qc "$SCT_BP_QC_FOLDER"
# Register template->mt1
# Tips: here we only use the segmentations due to poor SC/CSF contrast at the bottom slice.
# Tips: First step: slicereg based on images, with large smoothing to capture potential motion between anat and mt, then at second step: bpslinesyn in order to adapt the shape of the cord to the mt modality (in case there are distortions between anat and mt).
sct_register_multimodal -i "${SCT_DIR}/data/PAM50/template/PAM50_t2.nii.gz" \
	-iseg "$SCT_DIR/data/PAM50/template/PAM50_cord.nii.gz" \
	-d ${file_mt1}_crop.nii.gz -dseg ${file_mt1}_crop_seg.nii.gz \
	-param step=1,type=seg,algo=slicereg,smooth=3:step=2,type=seg,algo=bsplinesyn,slicewise=1,iter=3 \
	-initwarp ./warp_template2anat.nii.gz -initwarpinv ./warp_anat2template.nii.gz \
	-owarp warp_template2mt.nii.gz -owarpinv warp_mt2template.nii.gz
# Warp template
sct_warp_template -d ${file_mt1}_crop.nii.gz -w warp_template2mt.nii.gz -qc "$SCT_BP_QC_FOLDER"
# Compute mtr
sct_compute_mtr -mt0 ${file_mt0}_reg.nii.gz -mt1 ${file_mt1}_crop.nii.gz
# Register t1w->mt1
# Tips: We do not need to crop the t1w image before registration because step=0 of the registration is to put the source image in the space of the destination image (equivalent to cropping the t1w)
sct_register_multimodal -i ${SUBJECT}_run-1_T1w.nii.gz -d ${file_mt1}_crop.nii.gz \
	-dseg ${file_mt1}_crop_seg.nii.gz \
	-param step=1,type=im,algo=slicereg,metric=CC -x spline \
	-qc "$SCT_BP_QC_FOLDER"
# Compute MTsat
# Tips: Check your TR and Flip Angle from the Dicom data
sct_compute_mtsat -mt ${file_mt1}_crop.nii.gz \
	-pd ${file_mt0}_reg.nii.gz \
	-t1 ${SUBJECT}_run-1_T1w_reg.nii.gz -trmt 0.030 -trpd 0.030 -trt1 0.015 -famt 9 -fapd 9 -fat1 15
# Extract MTR, T1 and MTsat within the white matter between C2 and C5.
# Tips: Here we use "-discard-neg-val 1" to discard inconsistent negative values in MTR calculation which are caused by noise.

# compute MTR in dorsal columns between levels C2 and C5 (append across subjects) -l 53
sct_extract_metric -i mtr.nii.gz -vert 2:5 -vertfile label_MT/template/PAM50_levels.nii.gz \
	-method map -o "${PATH_RESULTS}/MTR_in_SC.csv" -append 1

sct_extract_metric -i mtr.nii.gz -vert 2:5 -l 51,30,31,34,35 \
    -perlevel 1 -method map -o "${PATH_RESULTS}/WM_and_ventral_dorsal_horn.csv" -append 1

sct_extract_metric -i mtsat.nii.gz -method map -o ${PATH_RESULTS}/mtsat_in_wm.csv -append 1 \
	-l 51 -vert 2:5

# Bring MTR to template space (e.g. for group mapping)
sct_apply_transfo -i mtr.nii.gz -d "${SCT_DIR}/data/PAM50/template/PAM50_t2.nii.gz" -w warp_mt2template.nii.gz


# dmri
# ===========================================================================================

cd ../dwi/
file_dwi="${SUBJECT}_run-1_dwi"

# bring t2 segmentation in dmri space to create mask (no optimization)
sct_dmri_separate_b0_and_dwi -i ${file_dwi}.nii.gz -bvec ${file_dwi}.bvec 
sct_register_multimodal -i ../anat/${file_t2}_seg.nii.gz -d ${file_dwi}_dwi_mean.nii.gz -identity 1 -x nn
# create mask to help moco and for faster processing
sct_create_mask -i ${file_dwi}_dwi_mean.nii.gz -p centerline,${file_t2}_seg_reg.nii.gz -size 35mm -o ${file_dwi}_mask_dwi_mean.nii.gz
# crop data
sct_crop_image -i ${file_dwi}.nii.gz -m ${file_dwi}_mask_dwi_mean.nii.gz -o dmri_crop.nii.gz
# motion correction
# Tips: if data have very low SNR you can increase the number of successive images that are averaged into group with "-g". Also see: sct_dmri_moco -h
sct_dmri_moco -i dmri_crop.nii.gz -bvec ${file_dwi}.bvec
# segment spinal cord
sct_deepseg_sc -i dmri_crop_moco_dwi_mean.nii.gz -c dwi -qc "$SCT_BP_QC_FOLDER"
# Generate QC for sct_dmri_moco ('dmri_crop_moco_dwi_mean_seg.nii.gz' is needed to align each slice in the QC mosaic)
sct_qc -i dmri_crop.nii.gz -d dmri_crop_moco.nii.gz -s dmri_crop_moco_dwi_mean_seg.nii.gz \
	-p sct_dmri_moco -qc "$SCT_BP_QC_FOLDER"
# Register template to dwi
# Tips: Again, here, we prefer to stick to segmentation-based registration. If there are susceptibility distortions in your EPI, then you might consider adding a third step with bsplinesyn or syn transformation for local adjustment.
sct_register_multimodal -i "$SCT_DIR/data/PAM50/template/PAM50_t1.nii.gz" \
	-iseg "$SCT_DIR/data/PAM50/template/PAM50_cord.nii.gz" \
	-d dmri_crop_moco_dwi_mean.nii.gz -dseg dmri_crop_moco_dwi_mean_seg.nii.gz \
	-param step=1,type=seg,algo=centermass:step=2,type=seg,algo=bsplinesyn,metric=MeanSquares,smooth=1,iter=3 \
	-initwarp ../anat/warp_template2anat.nii.gz \
	-initwarpinv ../anat/warp_anat2template.nii.gz \
	-qc "$SCT_BP_QC_FOLDER" -owarp warp_template2${file_dwi}.nii.gz \
	-owarpinv warp_dmri2template.nii.gz
# Warp template and white matter atlas
sct_warp_template -d dmri_crop_moco_dwi_mean.nii.gz -w warp_template2${file_dwi}.nii.gz -qc "$SCT_BP_QC_FOLDER"
# Compute DTI metrics
# Tips: The flag -method "restore" allows you to estimate the tensor with robust fit (see: sct_dmri_compute_dti -h)
sct_dmri_compute_dti -i dmri_crop_moco.nii.gz -bval ${file_dwi}.bval -bvec ${file_dwi}.bvec  -method "restore"
# Bring metric to template space (e.g. for group mapping)
sct_apply_transfo -i dti_FA.nii.gz -d "${SCT_DIR}/data/PAM50/template/PAM50_t2.nii.gz" -w warp_dmri2template.nii.gz

sct_extract_metric -i dti_FA.nii.gz \
		-f label/atlas \
		-method map \
		-vert 2:5 \
		-perlevel 1 \
		-o ${PATH_RESULTS}/fa_in_sc.csv \
		-append 1

# Compute FA within  dorsal and ventral horn  from slices 2 to 14 using weighted average method  
sct_extract_metric -i dti_FA.nii.gz \
		-vert 2:5 \
		-l 30,31,34,35 \
		-perlevel 1 \
		-method wa \
		-o "${PATH_RESULTS}/WM_and_ventral_dorsal_horn.csv" \
		-append 1

# Verify presence of output files and write log file if error
# ======================================================================================================================
FILES_TO_CHECK=(
    "$file_t2_seg.nii.gz"
    "mtr.nii.gz"
)
for file in "${FILES_TO_CHECK[@]}"; do
    if [ ! -e "${file}" ]; then
	echo "${SUBJECT}/${file} does not exist" >> "${PATH_LOG}/error.log"
    fi
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
