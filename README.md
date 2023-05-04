# GC-MS Sorting and Filtering Algorithm 

This skript was used to achieve a function only. Therefor it's not the prettiest one. 

## What is it?

This script is a part of GC-MS data aquisition pipeline. It's purpose was determined after getting a annotated peak list and before feeding the data into GCalignR for peak alignment.  This script was written to quickly analize a greater amount of GC-MS peaklists of collected volatiles of the liverwort *Marchantia polymorpha*. Therefor the test data is a part of that dataset.

## What is it for? What it can do?

The script does a rough data filtering, excluding peaks with a annotated compound probability below a certain threshold (80%) as well as compounds with an annotated biological non viable sum formula. It also filters compounds found in a given blank by retention time. The resulted list can then further be used for analysis and plotting.

## How to

1. Open the script in a new RStudio-Project.
2. Install the packages writexl and readxl and read in their libraries (line 21).

		install.packages("readxl")
		install.packages("writexl")

		library(readxl)
		library(writexl)

3. **Save the script on source** (Source on Save).
4. Collect all sample files in a folder in the project.
5. Make sure you have the path to your blank file.
6. *Optional* save the folder path to your sample files as the `sample_path` variable using the given syntax.
7. *Optional* save the file path to your blank file as the `blank_path` variable.
8. Provide a "results" folder in your project folder, or change the path where the results will be saved (see below)
8. Use the start_batch_processing function using your paths as arguments in the terminal.

		start_batch_processing(sample_path, blank_path)

## Input format

This script uses xlsx files. One file is used for one sample. The first sheet inhabits an annotated peak list:

![](https://github.com/KeilainMan/GC-MS_Sortingalgorithm_Marchantia/blob/main/pictures/peak_list_input.PNG)

The second sheet contains a spectrum search list giving about 25 search results for every peak, looking like this:

![](https://github.com/KeilainMan/GC-MS_Sortingalgorithm_Marchantia/blob/main/pictures/spectrum_search_list_1.PNG)
![](https://github.com/KeilainMan/GC-MS_Sortingalgorithm_Marchantia/blob/main/pictures/spectrum_search_list_2.PNG)
![](https://github.com/KeilainMan/GC-MS_Sortingalgorithm_Marchantia/blob/main/pictures/spectrum_search_list_3.PNG)

## Parameters and filtering process

The filtering happens in the sample files. Every compound annotation with an annotation score below 80% gets removed (Score is provided in column 3 on sheet 2 of the input file (SI)). You can alter the threshold by changing the 80 in the `check_for_probabilities` function.

		check_for_probabilities <- function(sample_peak_table){
  			for (row in 1:nrow(sample_peak_table)){
   				if (sample_peak_table[row, 14] >= 80){
     					 dffinal <- rbind(dffinal, sample_peak_table[row,])
  				}
  			}
 			dffinal <- polish_result(dffinal)
  			return(dffinal)
		}

The second filtering is through checking the sum formula for every compound in a sample. You can add to the list in the following function if nessasary:


		grepl_through_letters <- function(formula){
  			sum_formula_letters <- c("Si", "S", "Br", "Cl", "F", "P")
 			for (letter in sum_formula_letters){
    				if (grepl(letter, formula)){
     					return(FALSE)
   				}
			}
  			return(TRUE)
		}

The third filtering is tied to the blank. Firstly all peaks get compared for retention time matching. Matching retention times are consired if the difference of blank and sample peak retention times is lower then 0.025. If they are matching the sum formula of both peaks will be compared and if that also matches, the peak will be removed from the sample. You can alter the retention time comparison in this function:

		check_retention_times_matching <- function(sample_rt, blank_rt){
 			if (abs(sample_rt-blank_rt)<0.025){
    				return(TRUE)
 			}else{
   				return(FALSE)
 			}
		}

** NOTE ** Compounds without sum formula or annotation score will not be removed, instead they are kept and get a filler sum formula (C) or a filler probability (80). This shall provide an conservative filtering method where possible novel compounds, that aren't found in a annotation database will not be deleted from a dataset.

The results will be saved as "result_table_YOURSAMPLEINPUTNAME.xlsx" in a results folder in your project folder. To change this provide another path to the following function.

		save_file_with_formulas_as_xlsx <- function(dataframe, filename){
 			write_xlsx(dataframe ,paste("./test_data/results/result_table" ,  filename, sep = "_"))
  
  
		}
## Disclaimer 

There is no responsability provided in case of malfunctioning of the script. This script is not perfect in any way and was made to fulfill a specific purpose. It does not provide a complete foolproof removal of compounds that are not of interest. Therefor a manual revision of the resulted data is advised.

