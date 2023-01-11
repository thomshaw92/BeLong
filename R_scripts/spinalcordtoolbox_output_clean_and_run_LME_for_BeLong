# Libraries
library(ggplot2)
library(dplyr)
library(tidyr)
library(tidyverse)
library(stringr)
library(readr)
library(patchwork)
library(readxl)

##start cleaning the output from SCT

rm(all_data) # remove the all_data object
results_dir <- "C:/Users/thoma/OneDrive - The University of Queensland/Projects/BeLong/results/SCT_output/results_20230111/results/"
all_data <- data.frame()
files_list <- list.files(path = results_dir, pattern = ".csv")
for (file in files_list){
  if(file %in% c("MTR_in_WM_ventral_dorsal_horn.csv", "WM_and_ventral_dorsal_horn.csv")){
    df <- read.csv(file.path(results_dir, file), sep = ",")
    df_clean <- df %>% 
      mutate(Subject = str_extract(Filename, "(?<=sub-)\\d+"),
             ScanType = str_extract(Filename, "(mtr|FA|T2starw_wmseg|T2starw_gmseg|T2w_seg)"),
             Session = str_extract(Filename, "(?<=ses-)\\d+")) %>%
      select(Subject, Session, ScanType, VertLevel, Label, `MAP`, `STD`)
    df_clean$VertLevel <- as.factor(df_clean$VertLevel)
    all_data <- bind_rows(all_data, df_clean)
  }
  else if(file %in% c("t2s_wm_volume.csv", "t2s_gm_volume.csv", "t2w_CSA.csv")){
    df <- read.csv(file.path(results_dir, file), sep = ",")
    df_clean <- df %>%
      mutate(Subject = str_extract(Filename, "(?<=sub-)\\d+"),
             ScanType = str_extract(Filename, "(mtr|FA|T2starw_wmseg|T2starw_gmseg|T2w_seg)"),
             Session = str_extract(Filename, "(?<=ses-)\\d+")) %>%
      select(Subject, Session, ScanType, VertLevel, `MEANAREA`, `STDAREA`)
    df_clean$VertLevel <- as.factor(df_clean$VertLevel)
    all_data <- bind_rows(all_data, df_clean)
    all_data$VertLevel<-as.factor(all_data$VertLevel)
  }
}
# Read in the clinical data
clinical_data <- read_excel("C:/Users/thoma/OneDrive - The University of Queensland/Projects/BeLong/clinical_neuropsyc/master_clin_neuropsyc.xlsx", 
                            sheet = "BeLong_Neuropsyc", 
                            col_names = TRUE)
# Extract the columns you need from the clinical data
clinical_data$Subject <- sapply(strsplit(clinical_data$SubjID, "-"), "[[", 2)
clinical_data$Session <- sapply(strsplit(clinical_data$sesID, "-"), "[[", 2)
clinical_data <- clinical_data %>%
  select(Subject, Session, DOB, formal_diagnosis)
all_data <- merge(all_data, clinical_data, by = c("Subject", "Session"))


# read the "Clinical_subscores" sheet from the excel file
clinical_subscores <- read_excel("C:/Users/thoma/OneDrive - The University of Queensland/Projects/BeLong/clinical_neuropsyc/master_clin_neuropsyc.xlsx", sheet = "Clinical_subscores")
# keep only the needed columns - rename stupid minus sign
clinical_subscores$Subject <- sapply(strsplit(clinical_subscores$SubjID, "-"), "[[", 2)
clinical_subscores$Session <- sapply(strsplit(clinical_subscores$SesID, "-"), "[[", 2)
clinical_subscores <- clinical_subscores %>%
  rename(PLSFRS_total = `PLSFRS-total`,
         PLSFRS_bulbar = `PLSFRS-bulbar`,
         PLSFRS_finemotor = `PLSFRS-finemotor`,
         PLSFRS_grossmotor = `PLSFRS-grossmotor`,
         PLSFRS_resp = `PLSFRS-resp`)
clinical_subscores <- clinical_subscores %>%
  select(Subject, Session, PLSFRS_total, PLSFRS_bulbar, PLSFRS_finemotor, PLSFRS_grossmotor, PLSFRS_resp)
# merge the clinical_subscores data with all_data, using Subject and Session columns as key
all_data <- merge(all_data, clinical_subscores, by = c("Subject", "Session"))


#create a time variable to measure the longitudinal change (NB this should change in the future to reflect difference in session date)
all_data$time <- ifelse(all_data$Session=="01","baseline",ifelse(all_data$Session=="02","follow_up","other"))
all_data <- all_data %>%
  mutate(time_since_baseline = ifelse(Session == 02, 6, 0))

#We will use Bayesian  LMEs to model the longitudinal change in each spinal cord metric 
#(FA, MTR, gray matter area, white matter area, and cord surface area) as a function of time, 
#and include random intercepts and slopes for each subject. 
#we will also include fixed effects for the clinical scores (PLSFRS_total) and formal diagnosis as predictors.

#rearrange the data for STAN

LME_data <- all_data %>%
  group_by(Subject, Session, ScanType,formal_diagnosis,PLSFRS_total,PLSFRS_bulbar,PLSFRS_finemotor,PLSFRS_grossmotor,PLSFRS_resp,time_since_baseline) %>%
  summarize(MAP_mean = mean(MAP, na.rm = TRUE),
            MEANAREA_mean = mean(MEANAREA, na.rm = TRUE))
LME_data$time_since_baseline <- ifelse(LME_data$Session == "01", 0, 6)


LME_data_FA <- LME_data[LME_data$ScanType == "FA", ]


#install.packages("rstan", repos = c("https://mc-stan.org/r-packages/", getOption("repos")))

library(rstan)
rstan_options(auto_write = TRUE)
# Define the Stan model
stan_model <- "
data {
    int<lower=1> N; //number of observations
    int<lower=1> subject[N]; //subject identifier
    real<lower=0> time_since_baseline[N]; //time since baseline
    real<lower=0> T2Starw_gm_mean[N]; 
    real<lower=0> FA_mean[N];
    real<lower=0> mtr_mean[N];
    real<lower=0> T2w_seg_mean[N];
    real<lower=0> T2starw_wmseg_mean[N];
    real<lower=0> PLSFRS_total[N]; //clinical score
    int <lower=1, upper=4> formal_diagnosis[N]; // form of diagnosis
}

parameters {
    real alpha; //random intercept
    real beta; //random slope
    real b_PLSFRS_total; //coefficient for PLSFRS_total
    real b_formal_diagnosis[4]; //coefficient for formal diagnosis
    
}

transformed parameters {
      real T2Starw_gm_pred[N];
      real FA_pred[N];
      real mtr_pred[N];
      real T2w_seg_pred[N];
      real T2starw_wmseg_pred[N];
    for (i in 1:N) {
        T2Starw_gm_pred[i] = alpha + beta*time_since_baseline[i] + b_PLSFRS_total*PLSFRS_total[i] + b_formal_diagnosis[formal_diagnosis[i]];
        FA_pred[i] = alpha + beta*time_since_baseline[i] + b_PLSFRS_total*PLSFRS_total[i] + b_formal_diagnosis[formal_diagnosis[i]];
        mtr_pred[i] = alpha + beta*time_since_baseline[i] + b_PLSFRS_total*PLSFRS_total[i] + b_formal_diagnosis[formal_diagnosis[i]];
        T2w_seg_pred[i] = alpha + beta*time_since_baseline[i] + b_PLSFRS_total*PLSFRS_total[i] + b_formal_diagnosis[formal_diagnosis[i]];
        T2starw_wmseg_pred[i] = alpha + beta*time_since_baseline[i] + b_PLSFRS_total*PLSFRS_total[i] + b_formal_diagnosis[formal_diagnosis[i]];
    }

}

model {
    for (i in 1:4) {
        b_formal_diagnosis[i] ~ normal(0, 10);
    }
    alpha ~ normal(0, 10);
    beta ~ normal(0, 10);
    b_PLSFRS_total ~ normal(0, 10);
    T2Starw_gm_mean ~ normal(T2Starw_gm_pred, 10);
    FA_mean ~ normal(FA_pred, 10);
    mtr_mean ~ normal(mtr_pred, 10);
    T2w_seg_mean ~ normal(T2w_seg_pred, 10);
    T2starw_wmseg_mean ~ normal(T2starw_wmseg_pred, 10);
}
"
#data
stan_data <- list(N=nrow(LME_data), # Number of observations
                  y_T2Starw_gm_mean = LME_data$MAP_mean,
                  y_FA_mean = LME_data$MEANAREA_mean,
                  y_mtr_mean = LME_data$
                  subject = as.numeric(as.factor(LME_data$Subject)),
                  formal_diagnosis = as.numeric(as.factor(LME_data$formal_diagnosis)),
                  time = LME_data$time_since_baseline,
                  score = LME_data$PLSFRS_total)

fit <- stan(model_code = stan_model, data = stan_data, iter = 10000, warmup = 500, chains = 4, verbose = "TRUE")
