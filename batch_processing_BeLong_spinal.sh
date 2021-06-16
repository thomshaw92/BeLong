#!/bin/bash
#
# Example of commands to process multi-parametric data of the spinal cord.
#
# Please note that this batch script has a lot of redundancy and should not
# be used as a pipeline for regular processing. For example, there is no need
# to process both t1 and t2 to extract CSA values.
#
# For information about acquisition parameters, see: https://osf.io/wkdym/
# N.B. The parameters are set for these type of data. With your data, parameters
# might be slightly different.
#
# Usage:
#
#   [option] $SCT_DIR/batch_processing.sh
#
#   Prevent (re-)downloading sct_example_data:
#   SCT_BP_DOWNLOAD=0 $SCT_DIR/batch_processing.sh
#
#   Specify quality control (QC) folder (Default is ~/qc_batch_processing):
#   SCT_BP_QC_FOLDER=/user/toto/my_qc_folder $SCT_DIR/batch_processing.sh
subjName="sub-001"
SCT_data_dir="/vnm/BeLong_BIDS/${subjName}"
SCT_out_dir="/vnm/BeLong_BIDS/derivatives/${subjName}/SCT_output"
SCT_BP_QC_FOLDER="/vnm/BeLong_BIDS/derivatives/${subjName}/SCT_qc"
mkdir -p ${SCT_out_dir}
SCT_DIR="/vnm/sct_5.3"
# Abort on error
set -ve


# For full verbose, uncomment the next line
# set -x

# Fetch OS type
if uname -a | grep -i  darwin > /dev/null 2>&1; then
  # OSX
  open_command="open"
elif uname -a | grep -i  linux > /dev/null 2>&1; then
  # Linux
  open_command="xdg-open"
fi

# Check if users wants to use his own data (i don't - set to 0)
	SCT_BP_DOWNLOAD=0

# Remove QC folder
if [ -z "$SCT_BP_NO_REMOVE_QC" -a -d "$SCT_BP_QC_FOLDER" ]; then
  echo "Removing $SCT_BP_QC_FOLDER folder."
  rm -rf "$SCT_BP_QC_FOLDER"
fi

# get starting time:
start=`date +%s`

#cd into correct dir
cd ${SCT_data_dir}

# t2
# ===========================================================================================
cd anat
##START HERE AND MAKE A FOLDER PER MODALITY - COPY ACROSS THE FILES

# Segment spinal cord
<<COMMENT
sct_deepseg_sc -i ${subjName}_acq-spine_run-1_T2w.nii.gz \
-c t2 \
-kernel 3d \
-o ${SCT_out_dir}/t2_deepseg.nii.gz \
-qc "$SCT_BP_QC_FOLDER"
# Tips: If you are not satisfied with the results you can try with another algorithm:
# sct_propseg -i t2.nii.gz -c t2 -qc "$SCT_BP_QC_FOLDER"
# Vertebral labeling
# Tips: for manual initialization of labeling by clicking at disc C2-C3, use flag -initc2
sct_label_vertebrae -i ${subjName}_acq-spine_run-1_T2w.nii.gz \
-s ${SCT_out_dir}/t2_deepseg.nii.gz \
-c t2 \
-qc "$SCT_BP_QC_FOLDER" \
-ofolder ${SCT_out_dir}
# Create labels at in the cord at C2 and C5 mid-vertebral levels

sct_label_utils -i ${SCT_out_dir}/t2_deepseg_labeled.nii.gz \
-vert-body 2,5 \
-o ${SCT_out_dir}/labels_vert.nii.gz
# Tips: you can also create labels manually using:
# sct_label_utils -i t2.nii.gz -create-viewer 2,5 -o labels_vert.nii.gz
# Register to template
sct_register_to_template -i ${subjName}_acq-spine_run-1_T2w.nii.gz \
-s ${SCT_out_dir}/t2_deepseg.nii.gz \
-l ${SCT_out_dir}/labels_vert.nii.gz \
-c t2 \
-ofolder ${SCT_out_dir} \
-qc "$SCT_BP_QC_FOLDER"

# Tips: If you are not satisfied with the results, you can tweak registration parameters.
# For example here, we would like to take into account the rotation of the cord, as well as
# adding a 3rd registration step that uses the image intensity (not only cord segmentations).
# so we could do something like this:
# sct_register_multimodal -i $SCT_DIR/data/PAM50/template/PAM50_t2s.nii.gz -iseg $SCT_DIR/data/PAM50/template/PAM50_cord.nii.gz -d t2s.nii.gz -dseg t2s_seg.nii.gz -param step=1,type=seg,algo=slicereg,smooth=3:step=2,type=seg,algo=bsplinesyn,slicewise=1,iter=3 -initwarp ../t2/warp_template2anat.nii.gz
# Warp template without the white matter atlas (we don't need it at this point)
sct_warp_template -d ${subjName}_acq-spine_run-1_T2w.nii.gz \
-w ${SCT_out_dir}/warp_template2anat.nii.gz \
-a '0' -ofolder ${SCT_out_dir} 

# Compute cross-sectional area (and other morphometry measures) for each slice
sct_process_segmentation -i ${SCT_out_dir}/t2_deepseg.nii.gz \
-o ${SCT_out_dir}/csa.csv \
-qc "$SCT_BP_QC_FOLDER"



# Compute cross-sectional area and average between C2 and C3 levels
sct_process_segmentation -i ${SCT_out_dir}/t2_deepseg.nii.gz \
-vertfile ${SCT_out_dir}/template/PAM50_levels.nii.gz \
-vert 2:3 -o ${SCT_out_dir}/csa_c2c3.csv


# t2star 
# ===========================================================================================

# Spinal cord segmentation
sct_deepseg_sc -i ${subjName}_acq-spineGREME_run-1_T2star.nii.gz \
-c t2s \
-kernel 3d \
-o ${SCT_out_dir}/t2s_deepseg.nii.gz \
-qc "$SCT_BP_QC_FOLDER"

# Segment gray matter ##TRY -t option at some point
sct_deepseg_gm -i ${subjName}_acq-spineGREME_run-1_T2star.nii.gz \
-m large \
-o ${SCT_out_dir}/t2s_deepseg_GM.nii.gz \
-qc "$SCT_BP_QC_FOLDER"

# Register template->t2s (using warping field generated from template<->t2 registration)
sct_register_multimodal -i $SCT_DIR/data/PAM50/template/PAM50_t2s.nii.gz \
-iseg $SCT_DIR/data/PAM50/template/PAM50_cord.nii.gz \
-d ${subjName}_acq-spineGREME_run-1_T2star.nii.gz \
-dseg ${SCT_out_dir}/t2s_deepseg.nii.gz \
-param step=1,type=seg,algo=centermass:step=2,type=seg,algo=bsplinesyn,slicewise=1,iter=3:step=3,type=im,algo=syn,slicewise=1,iter=1,metric=CC \
-initwarp ${SCT_out_dir}/warp_template2anat.nii.gz \
-initwarpinv ${SCT_out_dir}/warp_anat2template.nii.gz \
-ofolder ${SCT_out_dir}/multimodal_template_reg_t2_t2s \
#-o ${SCT_out_dir}/t2s_src_reg

# rename warping fields for clarity
mv ${SCT_out_dir}/multimodal_template_reg_t2_t2s/warp_PAM50_t2s2sub-001_acq-spineGREME_run-1_T2star.nii.gz ${SCT_out_dir}/warp_template2t2s.nii.gz
mv ${SCT_out_dir}/multimodal_template_reg_t2_t2s/warp_sub-001_acq-spineGREME_run-1_T2star2PAM50_t2s.nii.gz ${SCT_out_dir}/warp_t2s2template.nii.gz

COMMENT

cd ${SCT_out_dir}

# Warp template
sct_warp_template -d ${SCT_data_dir}/anat/${subjName}_acq-spineGREME_run-1_T2star.nii.gz \
-w warp_template2t2s.nii.gz \
-ofolder sct_warp_template_t2s

# Subtract GM segmentation from cord segmentation to obtain WM segmentation
sct_maths -i ${SCT_out_dir}/t2s_deepseg.nii.gz -sub ${SCT_out_dir}/t2s_deepseg_GM.nii.gz \
-o ${SCT_out_dir}/t2s_wmseg.nii.gz

# Compute cross-sectional area of the gray and white matter between C2 and C5
sct_process_segmentation -i ${SCT_out_dir}/t2s_wmseg.nii.gz \
-vert 2:5 \
-perlevel 1 \
-vertfile ${SCT_out_dir}/template/PAM50_levels.nii.gz \
-o ${SCT_out_dir}/csa_wm.csv
# \

sct_process_segmentation -i ${SCT_out_dir}/t2s_deepseg_GM.nii.gz \
 -vertfile ${SCT_out_dir}/template/PAM50_levels.nii.gz \
 -vert 2:5 \
 -perlevel 1 \
 -o ${SCT_out_dir}/csa_gm.csv
# OPTIONAL: Update template registration using information from gray matter segmentation
# # <<<
# # Register WM/GM template to WM/GM seg
# sct_register_multimodal -i $SCT_DIR/data/PAM50/template/PAM50_wm.nii.gz -d t2s_wmseg.nii.gz -dseg t2s_seg.nii.gz -param step=1,type=im,algo=syn,slicewise=1,iter=5 -initwarp warp_template2t2s.nii.gz -initwarpinv warp_t2s2template.nii.gz -qc "$SCT_BP_QC_FOLDER"
# # Rename warping fields for clarity
# mv warp_PAM50_wm2t2s_wmseg.nii.gz warp_template2t2s.nii.gz
# mv warp_t2s_wmseg2PAM50_wm.nii.gz warp_t2s2template.nii.gz
# # Warp template (this time corrected for internal structure)
# sct_warp_template -d t2s.nii.gz -w warp_template2t2s.nii.gz
# # >>>

# t1
# ===========================================================================================
#This isn't needed? Maybe if  the quality fails on T2w?
# Segment spinal cord
sct_deepseg_sc -i ${SCT_data_dir}/anat/sub-001_acq-spine_run-1_T1w.nii.gz \
-c t1 \
-kernel 3d \
-o ${SCT_out_dir}/t1_deepseg.nii.gz \
-qc "$SCT_BP_QC_FOLDER"

# Smooth spinal cord along superior-inferior axis
sct_smooth_spinalcord -i ${SCT_data_dir}/anat/sub-001_acq-spine_run-1_T1w.nii.gz \
-s ${SCT_out_dir}/t1_deepseg.nii.gz
# Flatten cord in the right-left direction (to make nice figure)
sct_flatten_sagittal -i ${SCT_data_dir}/anat/sub-001_acq-spine_run-1_T1w.nii.gz \
 -s ${SCT_out_dir}/t1_deepseg.nii.gz


exit 0 
# mt
# ===========================================================================================
cd mt
# Get centerline from mt1 data
sct_get_centerline -i mt1.nii.gz -c t2
# sct_get_centerline -i mt1.nii.gz -c t2 -qc "$SCT_BP_QC_FOLDER"
# Create mask
sct_create_mask -i mt1.nii.gz -p centerline,mt1_centerline.nii.gz -size 45mm
# Crop data for faster processing
sct_crop_image -i mt1.nii.gz -m mask_mt1.nii.gz -o mt1_crop.nii.gz
# Segment spinal cord
sct_deepseg_sc -i mt1_crop.nii.gz -c t2 -qc "$SCT_BP_QC_FOLDER"
# Register mt0->mt1
# Tips: here we only use rigid transformation because both images have very similar sequence parameters. We don't want to use SyN/BSplineSyN to avoid introducing spurious deformations.
# Tips: here we input -dseg because it is needed by the QC report
sct_register_multimodal -i mt0.nii.gz -d mt1_crop.nii.gz -dseg mt1_crop_seg.nii.gz -param step=1,type=im,algo=rigid,slicewise=1,metric=CC -x spline -qc "$SCT_BP_QC_FOLDER"
# Register template->mt1
# Tips: here we only use the segmentations due to poor SC/CSF contrast at the bottom slice.
# Tips: First step: slicereg based on images, with large smoothing to capture potential motion between anat and mt, then at second step: bpslinesyn in order to adapt the shape of the cord to the mt modality (in case there are distortions between anat and mt).
sct_register_multimodal -i $SCT_DIR/data/PAM50/template/PAM50_t2.nii.gz -iseg $SCT_DIR/data/PAM50/template/PAM50_cord.nii.gz -d mt1_crop.nii.gz -dseg mt1_crop_seg.nii.gz -param step=1,type=seg,algo=slicereg,smooth=3:step=2,type=seg,algo=bsplinesyn,slicewise=1,iter=3 -initwarp ../t2/warp_template2anat.nii.gz -initwarpinv ../t2/warp_anat2template.nii.gz
# Rename warping fields for clarity
mv warp_PAM50_t22mt1_crop.nii.gz warp_template2mt.nii.gz
mv warp_mt1_crop2PAM50_t2.nii.gz warp_mt2template.nii.gz
# Warp template
sct_warp_template -d mt1_crop.nii.gz -w warp_template2mt.nii.gz -qc "$SCT_BP_QC_FOLDER"
# Compute mtr
sct_compute_mtr -mt0 mt0_reg.nii.gz -mt1 mt1_crop.nii.gz
# Register t1w->mt1
# Tips: We do not need to crop the t1w image before registration because step=0 of the registration is to put the source image in the space of the destination image (equivalent to cropping the t1w)
sct_register_multimodal -i t1w.nii.gz -d mt1_crop.nii.gz -dseg mt1_crop_seg.nii.gz -param step=1,type=im,algo=rigid,slicewise=1,metric=CC -x spline -qc "$SCT_BP_QC_FOLDER"
# Compute MTsat
# Tips: Check your TR and Flip Angle from the Dicom data
sct_compute_mtsat -mt mt1_crop.nii.gz -pd mt0_reg.nii.gz -t1 t1w_reg.nii.gz -trmt 30 -trpd 30 -trt1 15 -famt 9 -fapd 9 -fat1 15
# Extract MTR, T1 and MTsat within the white matter between C2 and C5.
# Tips: Here we use "-discard-neg-val 1" to discard inconsistent negative values in MTR calculation which are caused by noise.
sct_extract_metric -i mtr.nii.gz -method map -o mtr_in_wm.csv -l 51 -vert 2:5
sct_extract_metric -i mtsat.nii.gz -method map -o mtsat_in_wm.csv -l 51 -vert 2:5
sct_extract_metric -i t1map.nii.gz -method map -o t1_in_wm.csv -l 51 -vert 2:5
# Bring MTR to template space (e.g. for group mapping)
sct_apply_transfo -i mtr.nii.gz -d $SCT_DIR/data/PAM50/template/PAM50_t2.nii.gz -w warp_mt2template.nii.gz
# Go back to root folder
cd ..


# dmri
# ===========================================================================================
cd dmri
# bring t2 segmentation in dmri space to create mask (no optimization)
sct_maths -i dmri.nii.gz -mean t -o dmri_mean.nii.gz
sct_register_multimodal -i ../t2/t2_seg.nii.gz -d dmri_mean.nii.gz -identity 1 -x nn
# create mask to help moco and for faster processing
sct_create_mask -i dmri_mean.nii.gz -p centerline,t2_seg_reg.nii.gz -size 35mm
# crop data
sct_crop_image -i dmri.nii.gz -m mask_dmri_mean.nii.gz -o dmri_crop.nii.gz
# motion correction
# Tips: if data have very low SNR you can increase the number of successive images that are averaged into group with "-g". Also see: sct_dmri_moco -h
sct_dmri_moco -i dmri_crop.nii.gz -bvec bvecs.txt
# segmentation with propseg
sct_deepseg_sc -i dmri_crop_moco_dwi_mean.nii.gz -c dwi -qc "$SCT_BP_QC_FOLDER"
# Generate QC for sct_dmri_moco ('dmri_crop_moco_dwi_mean_seg.nii.gz' is needed to align each slice in the QC mosaic)
sct_qc -i dmri_crop.nii.gz -d dmri_crop_moco.nii.gz -s dmri_crop_moco_dwi_mean_seg.nii.gz -p sct_dmri_moco -qc "$SCT_BP_QC_FOLDER"
# Register template to dwi
# Tips: Again, here, we prefer to stick to segmentation-based registration. If there are susceptibility distortions in your EPI, then you might consider adding a third step with bsplinesyn or syn transformation for local adjustment.
sct_register_multimodal -i $SCT_DIR/data/PAM50/template/PAM50_t1.nii.gz -iseg $SCT_DIR/data/PAM50/template/PAM50_cord.nii.gz -d dmri_crop_moco_dwi_mean.nii.gz -dseg dmri_crop_moco_dwi_mean_seg.nii.gz -param step=1,type=seg,algo=centermass:step=2,type=seg,algo=bsplinesyn,metric=MeanSquares,smooth=1,iter=3 -initwarp ../t2/warp_template2anat.nii.gz -initwarpinv ../t2/warp_anat2template.nii.gz -qc "$SCT_BP_QC_FOLDER"
# Rename warping fields for clarity
mv warp_PAM50_t12dmri_crop_moco_dwi_mean.nii.gz warp_template2dmri.nii.gz
mv warp_dmri_crop_moco_dwi_mean2PAM50_t1.nii.gz warp_dmri2template.nii.gz
# Warp template and white matter atlas
sct_warp_template -d dmri_crop_moco_dwi_mean.nii.gz -w warp_template2dmri.nii.gz -qc "$SCT_BP_QC_FOLDER"
# Compute DTI metrics
# Tips: The flag -method "restore" allows you to estimate the tensor with robust fit (see: sct_dmri_compute_dti -h)
sct_dmri_compute_dti -i dmri_crop_moco.nii.gz -bval bvals.txt -bvec bvecs.txt
# Compute FA within right and left lateral corticospinal tracts from slices 2 to 14 using weighted average method
sct_extract_metric -i dti_FA.nii.gz -z 2:14 -method wa -l 4,5 -o fa_in_cst.csv
# Bring metric to template space (e.g. for group mapping)
sct_apply_transfo -i dti_FA.nii.gz -d $SCT_DIR/data/PAM50/template/PAM50_t2.nii.gz -w warp_dmri2template.nii.gz


# Display results (to easily compare integrity across SCT versions)
# ===========================================================================================
set +v
end=`date +%s`
runtime=$((end-start))
echo "~~~"  # these are used to format as code when copy/pasting in github's markdown
echo "Version:         `sct_version`"
echo "Ran on:          `uname -nsr`"
echo "Duration:        $(($runtime / 3600))hrs $((($runtime / 60) % 60))min $(($runtime % 60))sec"
echo "---"
echo "t2/CSA:         " `awk -F"," ' {print $6}' t2/csa_c2c3.csv | tail -1`
echo "mt/MTR(WM):     " `awk -F"," ' {print $8}' mt/mtr_in_wm.csv | tail -1`
echo "t2s/CSA_GM:     " `awk -F"," ' {print $6}' t2s/csa_gm.csv | tail -1`
echo "t2s/CSA_WM:     " `awk -F"," ' {print $6}' t2s/csa_wm.csv | tail -1`
echo "dmri/FA(CST_r): " `awk -F"," ' {print $8}' dmri/fa_in_cst.csv | tail -1`
echo "dmri/FA(CST_l): " `awk -F"," ' {print $8}' dmri/fa_in_cst.csv | tail -2 | head -1`
echo "~~~"

# Display syntax to open QC report on web browser
echo "To open Quality Control (QC) report on a web-browser, run the following:"
echo "$open_command $SCT_BP_QC_FOLDER/index.html"
