#!/bin/bash

#remove all .DS_Store files
find /Volumes/BeLong/BeLong/BeLong_SCT_BIDS/ -name '.DS_Store' -type f -delete
PATH_DATA_PROCESSED="/Volumes/BeLong/BeLong/BeLong_SCT_BIDS/data_processed"
PATH_RESULTS="/Volumes/BeLong/BeLong/BeLong_SCT_BIDS/data_processed/results"
PATH_LOG="/Volumes/BeLong/BeLong/BeLong_SCT_BIDS/data_processed/log"
PATH_QC="/Volumes/BeLong/BeLong/BeLong_SCT_BIDS/data_processed/qc"
#remove the log or qc folder in BeLong_SCT_BIDS/data_processed
if [ -d "${PATH_LOG}" ]; then
    rm -r ${PATH_LOG}
    mkdir -p ${PATH_LOG}
fi
if [ -d "${PATH_QC}" ]; then
    rm -r ${PATH_QC}
    mkdir -p ${PATH_QC}
fi
#remove the results folder if exists
if [ -d "${PATH_RESULTS}" ]; then
	rm -r "${PATH_RESULTS}" 
	mkdir -o "${PATH_RESULTS}"
fi

#run the batch script
sct_run_batch -script /Volumes/BeLong/BeLong/BeLong_SCT_BIDS/process_data.sh -path-data /Volumes/BeLong/BeLong/BeLong_SCT_BIDS/ -itk-threads 20 \
    -jobs 5 -zip -continue-on-error 1 -path-output /Volumes/BeLong/BeLong/BeLong_SCT_BIDS/data_processed/ 
