#!/bin/bash
#TS 2022 09 26
#move finished QSMxT final output to SCT bids dir for downstream proc.

#a bit variable as QC is different and lots of different trials with sequence params

#choices based on manual inspection pass/fail for SNR and quality of qsmxt output
SCT_dir=/90days/uqtshaw/BeLong/BeLong_SCT_BIDS/
#sub-025/ses-01/qsm
final_qsm_dir=/90days/uqtshaw/BeLong/BeLong_QSMxT_BIDS/02_qsm/qsm_final
cd $final_qsm_dir
#head		
cp sub-005_ses-3_acq-qsmE01_run-1_phase_scaled_qsm_000_twopass_average.nii ${SCT_dir}/sub-005/ses-01/qsm/qsmH.nii
#Neck
cp sub-005_ses-5_acq-qsmPH00_run-1_phase_scaled_qsm_000_twopass_average.nii ${SCT_dir}/sub-005/ses-01/qsm/qsmN.nii
#H&N
cp sub-006_ses-2_acq-qsmE01_run-1_phase_scaled_qsm_000_twopass_average.nii ${SCT_dir}/sub-006/ses-01/qsm/qsmH.nii 
#no neck for 6
#head
cp sub-007_ses-1_acq-qsmE01_run-1_phase_scaled_qsm_000_twopass_average.nii ${SCT_dir}/sub-006/ses-01/qsm/qsmH.nii
#neck
cp sub-007_ses-10_acq-qsmE01_run-1_phase_scaled_qsm_000_twopass_average.nii ${SCT_dir}/sub-007/ses-01/qsm/qsmN.nii
#h&n
cp sub-011_ses-01_run-01_echo-01_part-phase_MEGRE_scaled_qsm_000_twopass_average.nii ${SCT_dir}/sub-011/ses-01/qsm/qsmH.nii
#no neck for 11
#H&N
cp sub-013_ses-01_run-01_echo-01_part-phase_MEGRE_scaled_qsm_000_twopass_average.nii ${SCT_dir}/sub-013/ses-01/qsm/qsmH.nii
#N
cp sub-013_ses-01_run-03_echo-01_part-phase_MEGRE_scaled_qsm_000_twopass_average.nii ${SCT_dir}/sub-013/ses-01/qsm/qsmN.nii
#H&N
cp sub-014_ses-01_run-01_echo-01_part-phase_MEGRE_scaled_qsm_000_twopass_average.nii ${SCT_dir}/sub-014/ses-01/qsm/qsmH.nii
#N
cp sub-014_ses-01_run-03_echo-01_part-phase_MEGRE_scaled_qsm_000_twopass_average.nii ${SCT_dir}/sub-014/ses-01/qsm/qsmN.nii
#H&N
cp sub-015_ses-01_run-01_echo-01_part-phase_MEGRE_scaled_qsm_000_twopass_average.nii ${SCT_dir}/sub-015/ses-01/qsm/qsmH.nii
#N 
cp sub-015_ses-01_run-03_echo-01_part-phase_MEGRE_scaled_qsm_000_twopass_average.nii ${SCT_dir}/sub-015/ses-01/qsm/qsmN.nii
#H&N
cp sub-016_ses-01_run-03_echo-01_part-phase_MEGRE_scaled_qsm_000_twopass_average.nii ${SCT_dir}/sub-016/ses-01/qsm/qsmH.nii
#n
cp sub-016_ses-01_run-05_echo-01_part-phase_MEGRE_scaled_qsm_000_twopass_average.nii ${SCT_dir}/sub-016/ses-01/qsm/qsmN.nii
#HN
cp sub-017_ses-01_run-01_echo-01_part-phase_MEGRE_scaled_qsm_000_twopass_average.nii ${SCT_dir}/sub-017/ses-01/qsm/qsmH.nii
#N
cp sub-017_ses-01_run-07_echo-01_part-phase_MEGRE_scaled_qsm_000_twopass_average.nii ${SCT_dir}/sub-017/ses-01/qsm/qsmN.nii
#H&N
cp sub-018_ses-01_run-01_echo-01_part-phase_MEGRE_scaled_qsm_000_twopass_average.nii ${SCT_dir}/sub-018/ses-01/qsm/qsmH.nii
#N
cp sub-018_ses-01_run-08_echo-01_part-phase_MEGRE_scaled_qsm_000_twopass_average.nii ${SCT_dir}/sub-018/ses-01/qsm/qsmN.nii
#HN
cp sub-019_ses-01_run-01_echo-01_part-phase_MEGRE_scaled_qsm_000_twopass_average.nii ${SCT_dir}/sub-019/ses-01/qsm/qsmH.nii
#N
cp sub-019_ses-01_run-04_echo-01_part-phase_MEGRE_scaled_qsm_000_twopass_average.nii ${SCT_dir}/sub-019/ses-01/qsm/qsmN.nii
#HN
cp sub-021_ses-01_run-01_echo-01_part-phase_MEGRE_scaled_qsm_000_twopass_average.nii ${SCT_dir}/sub-021/ses-01/qsm/qsmH.nii
#N
cp sub-021_ses-01_run-06_echo-01_part-phase_MEGRE_scaled_qsm_000_twopass_average.nii ${SCT_dir}/sub-021/ses-01/qsm/qsmH.nii
#all the same
for x in sub-020 sub-022 sub-023 sub-024 sub-025 sub-026 sub-027 sub-028 sub-029 ; do 
    cp ${x}_ses-01_run-01_echo-01_part-phase_MEGRE*.nii ${SCT_dir}/${x}/ses-01/qsm/qsmH.nii
    cp ${x}_ses-01_run-04_echo-01_part-phase_MEGRE*.nii ${SCT_dir}/${x}/ses-01/qsm/qsmN.nii
done

#sub-024_ses-01_run-01_echo-13_part-phase_MEGRE.nii sub-024_ses-01_run-01_echo-01_part-phase_MEGRE.nii
###################

#magnitude images

###################


cd /90days/uqtshaw/BeLong/BeLong_QSMxT_BIDS/01_qsmxt_niftis/
#/sub-005/ses-3/anat/sub-005_ses-3_acq-qsmE01_run-1_magnitude.nii.gz
#head		
cp sub-005/ses-3/anat/sub-005_ses-3_acq-qsmE01_run-1_magnitude.nii.gz ${SCT_dir}/sub-005/ses-01/qsm/qsmHM.nii.gz
#Neck
cp sub-005/ses-5/anat/sub-005_ses-5_acq-qsm_run-1_magnitude.nii.gz ${SCT_dir}/sub-005/ses-01/qsm/qsmNM.nii.gz
#H&N
cp sub-006/ses-2/anat/*E01_run-1_magnitude.nii.gz ${SCT_dir}/sub-006/ses-01/qsm/qsmHM.nii.gz
#no neck for 6
#head
cp sub-007/ses-1/anat/*E01_run-1_magnitude.nii.gz ${SCT_dir}/sub-006/ses-01/qsm/qsmHM.nii.gz
#neck
cp sub-007/ses-10/anat/*E01_run-1_magnitude.nii.gz ${SCT_dir}/sub-007/ses-01/qsm/qsmNM.nii.gz
#h&n   sub-015_ses-01_run-02_echo-01_part-mag_MEGRE.nii
cp sub-011/ses-01/anat/sub-011_ses-01_run-01_echo-01_part-mag_MEGRE.nii ${SCT_dir}/sub-011/ses-01/qsm/qsmHM.nii
#no neck for 11
#H&N
cp sub-013/ses-01/anat/sub-013_ses-01_run-01_echo-01_part-mag_MEGRE.nii ${SCT_dir}/sub-013/ses-01/qsm/qsmHM.nii
#N
cp sub-013/ses-01/anat/sub-013_ses-01_run-03_echo-01_part-mag_MEGRE.nii ${SCT_dir}/sub-013/ses-01/qsm/qsmNM.nii
#H&N
cp sub-014/ses-01/anat/sub-014_ses-01_run-01_echo-01_part-mag_MEGRE.nii ${SCT_dir}/sub-014/ses-01/qsm/qsmHM.nii
#N
cp sub-014/ses-01/anat/*_run-03_echo-01_part-mag_MEGRE.nii ${SCT_dir}/sub-014/ses-01/qsm/qsmNM.nii
#H&N
cp sub-015/ses-01/anat/*_run-01_echo-01_part-mag_MEGRE.nii ${SCT_dir}/sub-015/ses-01/qsm/qsmHM.nii
#N 
cp sub-015/ses-01/anat/*_run-03_echo-01_part-mag_MEGRE.nii ${SCT_dir}/sub-015/ses-01/qsm/qsmNM.nii
#H&N
cp sub-016/ses-01/anat/*_run-03_echo-01_part-mag_MEGRE.nii ${SCT_dir}/sub-016/ses-01/qsm/qsmHM.nii
#n
cp sub-016/ses-01/anat/*_run-05_echo-01_part-mag_MEGRE.nii ${SCT_dir}/sub-016/ses-01/qsm/qsmNM.nii
#HN/anat/
cp sub-017/ses-01/anat/*_run-01_echo-01_part-mag_MEGRE.nii ${SCT_dir}/sub-017/ses-01/qsm/qsmHM.nii
#N
cp sub-017/ses-01/anat/*_run-07_echo-01_part-mag_MEGRE.nii ${SCT_dir}/sub-017/ses-01/qsm/qsmNM.nii
#H&N
cp sub-018/ses-01/anat/*_run-01_echo-01_part-mag_MEGRE.nii ${SCT_dir}/sub-018/ses-01/qsm/qsmHM.nii
#N
cp sub-018/ses-01/anat/*_run-08_echo-01_part-mag_MEGRE.nii ${SCT_dir}/sub-018/ses-01/qsm/qsmNM.nii
#HN
cp sub-019/ses-01/anat/*_run-01_echo-01_part-mag_MEGRE.nii ${SCT_dir}/sub-019/ses-01/qsm/qsmHM.nii
#N
cp sub-019/ses-01/anat/*_run-04_echo-01_part-mag_MEGRE.nii ${SCT_dir}/sub-019/ses-01/qsm/qsmNM.nii
#HN
cp sub-021/ses-01/anat/*_run-01_echo-01_part-mag_MEGRE.nii ${SCT_dir}/sub-021/ses-01/qsm/qsmHM.nii
#N
cp sub-021/ses-01/anat/*_run-06_echo-01_part-mag_MEGRE.nii ${SCT_dir}/sub-021/ses-01/qsm/qsmHM.nii
#all the same
for x in sub-020 sub-022 sub-023 sub-024 sub-025 sub-026 sub-027 sub-028 sub-029 ; do 
    cp ${x}/ses-01/anat/${x}_ses*_run-01_echo-01_part-mag_MEGRE.nii ${SCT_dir}/${x}/ses-01/qsm/qsmHM.nii
    cp ${x}/ses-01/anat/${x}_ses*_run-04_echo-01_part-mag_MEGRE.nii ${SCT_dir}/${x}/ses-01/qsm/qsmNM.nii
done
