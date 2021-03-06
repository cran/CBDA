#' @title
#' Stopping Criteria function for Compressive Big Data Analytics
#'
#' @description
#'  This CBDA function generates a stopping criteria for the *max_covs - min_covs* nested
#'  predictive models generated in the previous step. It also populates the CBDA object.

#' @param label This is the label appended to RData workspaces generated within the CBDA calls

#' @param Kcol_min Lower bound for the percentage of features-columns sampling (used for the Feature Sampling Range - FSR)

#' @param Kcol_max Upper bound for the percentage of features-columns sampling (used for the Feature Sampling Range - FSR)

#' @param Nrow_min 	Lower bound for the percentage of cases-rows sampling (used for the Case Sampling Range - CSR)

#' @param Nrow_max Upper bound for the percentage of cases-rows sampling (used for the Case Sampling Range - CSR)

#' @param misValperc Percentage of missing values to introduce in BigData (used just for testing, to mimic real cases).

#' @param M Number of the BigData subsets on which perform Knockoff Filtering and SuperLearner feature mining

#' @param workspace_directory Directory where the results and workspaces are saved

#' @param max_covs Top features to include in the Validation Step where nested models are tested

#' @param min_covs Minimum number of top features to include in the initial model for the Validation Step

#' @param lambda Fisher test threshold for MSE (=1.005 by default)

#' @return value

#' @export

CBDA_Stopping_Criteria <- function(label = "CBDA_package_test" , Kcol_min = 5 , Kcol_max = 15,
                            Nrow_min = 30 , Nrow_max = 50 , misValperc = 0, M = 3000 ,
                            workspace_directory = tempdir(), max_covs = 100 , min_covs = 5, lambda = 1.005) {

  range_n <- range_k <- qa_ALL <- algorithm_list <- cmatrix_ALL_validation <- NULL

  message("STOPPING cRITERIA GENERATION STEP HAS STARTED !!")
  filename_specs <- file.path(workspace_directory,paste0(label,"_info.RData"))
  #eval(parse(text=paste0("load(\"",workspace_directory,"/",label,"_info.RData\")")))
  load(filename_specs)

  filename <- file.path(workspace_directory,
                        paste0("CBDA_SL_M",M,"_miss",misValperc,"_n",range_n,
                               "_k",range_k,"_Light_",label,"_VALIDATION.RData"))
  load(filename)

  qa_ALL_Validation <- matrix(0,max_covs-min_covs+1,5)

  counter <- 1
  for(j_global in min_covs:max_covs)
  {
    eval(parse(text=paste0("qa_ALL_Validation[",counter,",1] <- ",j_global,"")))
    eval(parse(text=paste0("qa_ALL_Validation[",counter,",2] <- Accuracy_",j_global,"")))
    eval(parse(text=paste0("qa_ALL_Validation[",counter,",3] <- MSE_",j_global,"")))
    counter <- counter + 1
  }

  ## Stopping Criteria for Accuracy and MSE Performance Metrics
  ## Two more columns added with 0 (continue) and 1 (stop)
  StopAcc <- NULL
  StopMSE <- NULL
  for(i in 1:dim(qa_ALL_Validation)[1]-1)
  {
    # Simple improvement (1%,5%, 0.05% in Accuracy)
    ifelse((qa_ALL_Validation[i+1,2]/qa_ALL_Validation[i,2]) > lambda,
           StopAcc[i] <- "Keep Going", StopAcc[i] <- "Stop")
    # F of Fisher test
    ifelse((qa_ALL_Validation[i,3]/qa_ALL_Validation[i,3])/(qa_ALL_Validation[i+1,3]/qa_ALL_Validation[i+1,3])
           > stats::qf(.95, df1=qa_ALL_Validation[i,3], df2=qa_ALL_Validation[i+1,3]),
           StopMSE[i] <- "Keep Going", StopMSE[i] <- "Stop")
  }

  Stopping_Criteria <- data.frame(NumberOfTopFeatures=qa_ALL_Validation[,1],Inference_Acc=qa_ALL_Validation[,2],
                                  Inference_MSE = qa_ALL_Validation[,3] ,
                                  StopAcc=c(StopAcc,"NA"), StopMSE=c(StopMSE,"NA"))
  # StopAcc <- which(qa_ALL_Validation$StopAcc == 1)[1]
  # StopMSE <- which(qa_ALL_Validation$StopMSE == 1)[1]

  if(is.na(StopMSE[1]))
  {StopMSE <- StopAcc}

  CBDA_object[[1]] <- qa_ALL
  CBDA_object[[5]] <- Stopping_Criteria

  names(CBDA_object)[1] <- c("LearningTable")
  names(CBDA_object)[2] <- c("ConfusionMatrices")
  names(CBDA_object)[3] <- c("SuperLearnerLibrary")
  names(CBDA_object)[4] <- c("SuperLearnerCoefficients_Validation")
  names(CBDA_object)[5] <- c("ValidationTable")
  names(CBDA_object)[6] <- c("SuperLearnerCoefficients_Training")

  for (j in min_covs:max_covs)
  {
    eval(parse(text=paste0("rm(cmatrix_",j,")")))
    #eval(parse(text=paste0("rm(KO_result_",j,")")))
    eval(parse(text=paste0("rm(Accuracy_",j,")")))
  }

  filename <- file.path(workspace_directory,
                        paste0("CBDA_SL_M",M,"_miss",misValperc,"_n",range_n,
                               "_k",range_k,"_Light_",label,"_VALIDATION.RData"))
  save(list = ls(all.names = TRUE), file = filename)
#  eval(parse(text=paste0("save(list = ls(all.names = TRUE),
#                             file= \"",workspace_directory,"/CBDA_SL_M",M,"_miss",misValperc,"_n",range_n,"_k"
#                         ,range_k,"_Light_",label,"_VALIDATION.RData\")")))

  cat("Performance metrics for the nested Predictive models.\n")
  cat("VALIDATION TABLE\n")
  print(CBDA_object$ValidationTable)
  cat("\n\nStopping Criteria completed successfully !!\n\n")

  return(CBDA_object)
}


