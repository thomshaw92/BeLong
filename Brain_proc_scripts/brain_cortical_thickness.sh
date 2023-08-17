#!/bin/bash

#antsCortical Long. thickness script for extracting
#volume, SA, and cortical thickness for STIMMRI data
#Tom Shaw 21/06/2021

subjName="sub-001"
ml ants

#set up the directories - brain atlas is downloaded from OASIS and mindboggle
#TBC - make bespoke atlas from cohort.

data_dir="/vnm/BeLong_BIDS"
atlas_dir="/vnm/BeLong_ATLAS"
out_dir="/vnm/BeLong_BIDS/derivatives/alct/$subjName/${subjName}_long_cortical_thickness"

mkdir -p ${out_dir}
cd ${out_dir}

tp_1_t1w=$(echo "${data_dir}/${subjName}/ses-01/anat/${subjName}"*"T1w.nii.gz")
tp_2_t1w=$(echo "${data_dir}/${subjName}/ses-02/anat/${subjName}"*"T1w.nii.gz")
tp_3_t1w=$(echo "${data_dir}/${subjName}/ses-03/anat/${subjName}"*"T1w.nii.gz")

#ANTS LCT 3TP
if [[ ! -d /30days/uqtshaw/STIMMRI/alct/${subjName}/${subjName}_long_cortical_thickness ]] ; then
    antsLongitudinalCorticalThickness.sh -d 3 \
    -e ${atlas_dir}/STIMMRI_T1w_template0.nii.gz \
    -m ${atlas_dir}/antsCTBrainExtractionMaskProbabilityMask.nii.gz \
    -p ${atlas_dir}/antsCTBrainSegmentationPosteriors%d.nii.gz \
    -f ${atlas_dir}/antsCTBrainExtractionMask.nii.gz \
    -t ${atlas_dir}/antsCTBrainExtractionBrain.nii.gz \
    -o ${subjName}_long_cortical_thickness \
    -k '1' \
    -c '2' \
    -j '14' \
    -r '1' \
    -q '0' \
    -n '1' \
    -b '1' \
    ${tp_1_t1w} ${tp_2_t1w} ${tp_3_t1w}
fi

#JLF the data

for TP in 01 02 03 ; do
outdir_JLF=/30days/$USER/STIMMRI/alct/$subjName}/${subjName}_ses-${TP}/
    mkdir -p ${outdir_JLF}
    cd ${outdir_JLF}
    atlasDir=/30days/uqtshaw/mindboggle_all_data
    target_image=$(echo "${out_dir}/${subjName}_ses-${TP}_"*"/${subjName}_ses-${TP}_"*"T1wExtractedBrain0N4.nii.gz")
    if [[ -e ${target_image} ]] ; then
        command="antsJointLabelFusion.sh -d 3 -t ${target_image} -x or -o dkt_${TP} -c 2 -j 8"
        
        for i in {1..20} ;  do
            command="${command} -g ${atlasDir}/OASIS-TRT-20_volumes/OASIS-TRT-20-${i}/t1weighted_brain.nii.gz"
            command="${command} -l ${atlasDir}/OASIS-TRT-20_DKT31_CMA_labels_v2/OASIS-TRT-20-${i}_DKT31_CMA_labels.nii.gz"
        done
        
        $command
    fi
done