#script for filtering results of TDU PDSM-Tube measurements. 
#Needed is a an analysed chromatogram, every sample/blank data has to be an xlsx file
#with an GCMSPostrunAnalysis export of the quality peak table on sheet one and an export of the spectrum search table 
#(list of all searches) on sheet two

#GCPostrunAnalysis result pathway:
#load chromatogram
#click "Quality" -> "Peak Integration for all TICs"
# select favored integration mode(Auto area was tested with this script) and number of peaks(120 for this script,
#but number is not relevant for the script) ->proceed
# click "Qualitative Table" -> "TIC" -> Select all -> right click "Register to Spectrum Process Table
#-> "Spectrum Process" (check that just the wanted number of peaks is present) -> "Similarity Search 
#-> "Search All Table"
#"Top" -> "Create Compound Table" -> "Wizard (New)" -> change "Quantitive Method" to "Area Normalization" -> finish wizard
#"File" -> "Export Data" -> "Qualitative Peak Table"
#"File" -> "Export Data" -> "Spectrum Search Table"
#insert both exports into seperate sheets and delete headers but not coloum names!


#install all needed packages
install.packages("readxl")
install.packages("writexl")

#always read the packages in
library(readxl)
library(writexl)


sample_list <- c()
temp_file_name <- ""

sum_formulas <- c()
probabilities <- c()
peak_number = 0
sum_fs <- c()
probs <- c()
row_numbers <- c()

dffinal <- data.frame(
  Peak. = c(0),
  Ret.Time = c(0),
  Proc.From = c(0),
  Proc.To = c(0),
  Mass = c(0),
  Area = c(0),
  Height = c(0),
  A.H = c(0),
  Conc. = c(0),
  Mark = c(0),
  Name = c(0),
  Ret..Index = c(0),
  sumformula = c(0),
  probability = c(0)
)

df_file_peak_table <- data.frame(
  Peak. = c(0),
  Ret.Time = c(0),
  Proc.From = c(0),
  Proc.To = c(0),
  Mass = c(0),
  Area = c(0),
  Height = c(0),
  A.H = c(0),
  Conc. = c(0),
  Mark = c(0),
  Name = c(0),
  Ret..Index = c(0)
)

df_file_spectrum_table <- data.frame(
  Peak. = c(0),
  Ret.Time = c(0),
  Proc.From = c(0),
  Proc.To = c(0),
  Mass = c(0),
  Area = c(0),
  Height = c(0),
  A.H = c(0),
  Conc. = c(0),
  Mark = c(0),
  Name = c(0),
  Ret..Index = c(0)
)

df_blank_peak_table <- data.frame(
  Peak. = c(0),
  Ret.Time = c(0),
  Proc.From = c(0),
  Proc.To = c(0),
  Mass = c(0),
  Area = c(0),
  Height = c(0),
  A.H = c(0),
  Conc. = c(0),
  Mark = c(0),
  Name = c(0),
  Ret..Index = c(0)
)

df_blank_spectrum_table <- data.frame(
  Peak. = c(0),
  Ret.Time = c(0),
  Proc.From = c(0),
  Proc.To = c(0),
  Mass = c(0),
  Area = c(0),
  Height = c(0),
  A.H = c(0),
  Conc. = c(0),
  Mark = c(0),
  Name = c(0),
  Ret..Index = c(0)
)



#"P:\\Marchantiaprojekt\\220918_Main_Marchantia_Experiment\\Volatiles\\05_Data_Prepared_for_R_Filtering"
#"P:\\Marchantiaprojekt\\220918_Main_Marchantia_Experiment\\Volatiles\\04_02_Organized_TDU_Data_blanks\\agarblankD3.xlsx"

#Inputfunction: function for batchprocessing, input is the folder path and blank_path
#paths are given in "" and with \\
#all input data has to be xlsx, first sheet containing QualityPeakTable Export from GCPostAnalysis, 
#second sheet containing the export of all search result for every peak, exclude headers, but not coloum names
sample_path <- "./test_data/samples"
blank_path <- "./test_data/blank/agarblankD3.xlsx"


start_batch_processing <- function(folder_path, blank_data){
   sample_list <- import_all_samples(folder_path)
   import_blank(blank_data)
   for (file in sample_list){
     import_sample(file)
     temp_save_file_name(file)
     start_calculation_process(df_blank_peak_table, df_blank_spectrum_table, df_file_peak_table, df_file_spectrum_table)
   }
   print("fully done")
}

#helperfunction: creates a list of filepaths, for all sample files
import_all_samples <- function(dir_path){
  sample_list <- list.files(path = dir_path, pattern = ".xlsx", full.names = TRUE)
  return(sample_list)
}
  
#helperfunction: imports the blank.xlsx as two dataframes for calculation
import_blank <- function(blank_datei){
  blank_peak_table <- read_xlsx(blank_datei, sheet = 1, col_names = TRUE)
  blank_spectrum_table <- read_xlsx(blank_datei, sheet = 2, col_names = TRUE)
  df_blank_peak_table <<- data.frame(blank_peak_table)
  df_blank_spectrum_table <<- data.frame(blank_spectrum_table)
}

#helperfunction: imports a sample file as two dataframes for calculation
import_sample <- function(file_path){
  file_peak_table <- read_xlsx(file_path, sheet = 1, col_names = TRUE)
  file_spectrum_table <- read_xlsx(file_path, sheet = 2, col_names = TRUE)
  df_file_peak_table <<- data.frame(file_peak_table)
  df_file_spectrum_table <<- data.frame(file_spectrum_table)
  
}
  
#helperfunction: saves the filename of the currently working sample for later result export
temp_save_file_name <- function(file){
  temp_file_name <<- basename(file)
}


#managerfunction: for main calculationprocess, inputs previously created dataframes as input
#firstly adds the sumformulas from the spectrum search to the peak list, blank and sample
#secondly adds probabilities for found compound to sample peak list
#thirdly filters the resulting peak table to exclude peaks with a probability below the probability_threshold
#and exclude peaks with sumformulas that are unwanted, e.g. containing Si, Cl, Br etc.
#forthly substracts peaks that are found in the blank from the sample
#lastly it print the results as a xlsx
start_calculation_process <- function(blank_peak_table,
                                      blank_spectrum_table,
                                      sample_peak_table,
                                      sample_spectrum_table){
  
  blank_peak_table_wsf = add_sum_formula(blank_peak_table, blank_spectrum_table)
  sample_peak_table_wsf = add_sum_formula(sample_peak_table, sample_spectrum_table)
  #full_blank_peak_table = add_probability(blank_peak_table, blank_spectrum_table)
  full_sample_peak_table = add_probability(sample_peak_table_wsf, sample_spectrum_table)
  
  sample_peak_table_prob_adjust = check_for_probabilities(full_sample_peak_table)
  sample_peak_table_full_adjust = check_sum_formulas_for_sense(sample_peak_table_prob_adjust)
  
  final_sample_peak_table = substract_blank(blank_peak_table_wsf, sample_peak_table_full_adjust)
  
  save_file_with_formulas_as_xlsx(final_sample_peak_table, temp_file_name)

  print("done")
}


#helperfunction: adds the sum formula of the first search result to the corresponding peak in the peak list
#in no formula is given or a peak is missing a placeholder "C" is added
add_sum_formula <- function(peak_table, spectrum_search){
  for (spectrum_row_index in 1:nrow(spectrum_search)){
    if (spectrum_search[spectrum_row_index,2] == 1){
      if (spectrum_search[spectrum_row_index,1] - peak_number > 1){
        sum_formulas <- c(sum_formulas, add_filler_sum(abs(spectrum_search[spectrum_row_index,1] - peak_number -1)))
      }
      sum_formulas <- c(sum_formulas, spectrum_search[spectrum_row_index, 7])
      peak_number = spectrum_search[spectrum_row_index,1]
    }
  }
  dfpeak_table_copie = peak_table
  dfpeak_table_copie$sumformula <- sum_formulas
  
  return(dfpeak_table_copie)
}

#helperfunction: adds the probability of the first search result to the corresponding peak in the peak list
#if no probability is given or if a peak is missing a placeholder "80" is added
add_probability <- function(peak_table, spectrum_search){
  for (spectrum_row_index in 1:nrow(spectrum_search)){
    if (spectrum_search[spectrum_row_index,2] == 1){
      if (spectrum_search[spectrum_row_index,1] - peak_number > 1){
        probabilities <- c(probabilities, add_filler_prob(abs(spectrum_search[spectrum_row_index,1] - peak_number -1)))
      }
      probabilities <- c(probabilities, spectrum_search[spectrum_row_index, 3])
      peak_number = spectrum_search[spectrum_row_index,1]
    }
  }
  dfpeak_table_copie = peak_table
  dfpeak_table_copie$probability <- probabilities

  return(dfpeak_table_copie)
}

#helperfunction: adds every sample peak that has a proposed compound probability over the probability-threshold to a new 
#working dataframe
check_for_probabilities <- function(sample_peak_table){
  for (row in 1:nrow(sample_peak_table)){
    if (sample_peak_table[row, 14] >= 80){
      dffinal <- rbind(dffinal, sample_peak_table[row,])
    }
  }
  dffinal <- polish_result(dffinal)
  return(dffinal)
}

#helperfunction: adds every sample peak, that passes the test for unwanted sumformula letters to a new working dataframe
check_sum_formulas_for_sense <- function(sample_peak_table){
  for (row in 1:nrow(sample_peak_table)){
    formula = sample_peak_table[row,13]
    if (grepl_through_letters(formula)){
        dffinal <- rbind(dffinal, sample_peak_table[row,])
    }
  }
  dffinal <- polish_result(dffinal)
  return(dffinal)
}

#helperfunction: tests every sumformula for unwanted letters
grepl_through_letters <- function(formula){
  sum_formula_letters <- c("Si", "S", "Br", "Cl", "F", "P")
  for (letter in sum_formula_letters){
    if (grepl(letter, formula)){
      return(FALSE)
    }
  }
  return(TRUE)
}

#managerfunction: for substracting blankpeaks from samples 
#therefor it checks for parameters and not passing peaks will get deleted from the working dataframe
substract_blank <- function(blank, sample){
  for (blank_row_index in 1:nrow(blank)){
    for (sample_row_index in 1:nrow(sample)){
      if (do_comparison(sample[sample_row_index,], blank[blank_row_index,])){
        row_numbers <- c(row_numbers, sample_row_index)
        #print(row_numbers)
      }
      
    }
  }
  if (length(row_numbers) == 0){
    print("No Rows to remove")
    final_sample <- sample
  }else{
    final_row_numbers <- unique(row_numbers)
    #cat("row numbers: ", row_numbers)
   final_sample <- sample[-c(row_numbers),]}
  return(final_sample)
}
 
#helperfunction: checks samplepeak and blankpeak for similarity    
do_comparison <- function(sample_row, blank_row){
  if (check_retention_times_matching(sample_row[1,2], blank_row[1,2])){
    if (check_sum_formulas_matching(sample_row[1,13], blank_row[1,13])){
      return(TRUE)
    }else{
      return(FALSE)
    }
  }else{
    return(FALSE)
  }
}
  
#helperfunction: checks retention time of blankpeak and samplepeak 
check_retention_times_matching <- function(sample_rt, blank_rt){
  if (abs(sample_rt-blank_rt)<0.025){
    return(TRUE)
  }else{
    return(FALSE)
  }
}

#helperfunction: checks for similarity of the sum formulas of a given blankpeak and samplepeak
check_sum_formulas_matching <- function(sample_formula, blank_formula){
  if (is.na(sample_formula) | is.na(blank_formula)){
    return(FALSE)
  }
  if (sample_formula == blank_formula){
    return(TRUE)
  }else{
    return(FALSE)
  }
}

#helperfunction: deletes the initializationrow of the working dataframe
#exclude doubled peaks and collects only unique peaks
polish_result <- function(dfresult){
  dfresult <- dfresult[-c(1),]
  dfresult <- unique(dfresult)
  return(dfresult)
}

#helperfunction: for adding a sum formula filler
add_filler_sum <- function(x){
  for (i in 1:x){
    sum_fs <- c(sum_fs, "C")
  }
  return(sum_fs)
}

#helperfunction: for adding a probability filler
add_filler_prob <- function(x){
  for (i in 1:x){
    probs <- c(probs, "80")
  }
  return(probs)
}

#helperfunction: saveing the result as a xlsx file
save_file_with_formulas_as_xlsx <- function(dataframe, filename){
  write_xlsx(dataframe ,paste("./test_data/results/result_table" ,  filename, sep = "_"))
  
  
}
