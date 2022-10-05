ml spinalcordtoolbox
sct_run_batch -script ./process_data.sh -path-data /90days/uqtshaw/BeLong/BeLong_SCT_BIDS/ -itk-threads 40 -jobs 3 -zip -continue-on-error 1
#-path-output /90days/uqtshaw/BeLong/BeLong_SCT_BIDS/data_processed/ 
