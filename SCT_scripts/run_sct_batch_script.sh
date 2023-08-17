ml spinalcordtoolbox
ml ants
sct_run_batch -script ./preprocess_data_for_qsm.sh -path-data /90days/uqtshaw/BeLong/BeLong_SCT_BIDS/ -itk-threads 40 -jobs 3 -zip -continue-on-error 1
#-path-output /90days/uqtshaw/BeLong/BeLong_SCT_BIDS/data_processed/ 
