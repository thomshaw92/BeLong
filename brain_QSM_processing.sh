#!/bin/bash
#Make sure the application is downloaded in vnm by clicking it in the menu
subjName="sub-001"
raw_data_dir="/vnm/BeLong_raw/${subjName}"
out_dir="/vnm/BeLong_BIDS/derivatives/QSMxT_output/${subjName}"
mkdir -p ${out_dir}

# Abort on error
set -ve

#execute the commands from within singularity with this
singularity="singularity exec /cvmfs/neurodesk.ardc.edu.au/registry.hub.docker.com/vnmd/qsmxt_1.1.4\:20210611 python3 /opt/QSMxT/"

#first copy the data to a new raw_dir so that it doesn't double up too much.
mkdir -p ${out_dir}/raw_data_condensed

for file in ${raw_data_dir}/*Aspire_*_C2P_GRE_16ME_aspire_1mm_iso_new ; do
    cp -r ${file} ${out_dir}/raw_data_condensed/
done
for file in ${raw_data_dir}/*MPRAGE_0p8 ; do
    cp -r ${file} ${out_dir}/raw_data_condensed/
done

${singularity}/run_0_dicomSort.py ${out_dir}/raw_data_condensed ${out_dir}/00_dicom
${singularity}/run_1_dicomToBids.py ${out_dir}/00_dicom ${out_dir}/01_bids
#After this step check if the data were correctly recognized and converted to BIDS. Otherwise make a copy of /opt/QSMxT/bidsmap.yaml
# - adjust based on provenance example in 01_bids/code/bidscoin/bidsmap.yaml (see for example what it detected under extra_files) 
#- and run again with the parameter `--heuristic bidsmap.yaml`.  
#2. Run QSM pipeline:
${singularity}/run_2_qsm.py --two_pass ${out_dir}/01_bids ${out_dir}/02_qsm_output 
#3. Segment data (T1 and GRE):
${singularity}/run_3_segment.py ${out_dir}/01_bids ${out_dir}/03_segmentation
#4. Build magnitude and QSM group template (only makes sense when you have more than about 30 participants):
#${singularity}/run_4_template.py ${out_dir}/01_bids ${out_dir}/02_qsm_output ${out_dir}/04_template
#5. Export quantitative data to CSV using segmentations
${singularity}/run_5_analysis.py --labels_file ${script_dir}//QSMxT/aseg_labels.csv \
--segmentations ${out_dir}/03_segmentation/qsm_segmentations/*.nii --qsm_files ${out_dir}/02_qsm_output/qsm_final/*/*.nii \
--out_dir ${out_dir}/06_analysis
#cleanup
rm -r ${out_dir}/raw_data_condensed ${out_dir}/00_dicom