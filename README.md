# GC-MS sortingalgorithm 

This skript was used to achieve a function only. Therefor it's not the prettiest one. 

## What is it?

This script is a part of GC-MS data aquisition pipeline. It's purpose was determined after getting a annotated peak list and before feeding the data into GCalignR for peak alignment.  This script was written to quickly analize a greater amount of GC-MS peaklists of collected volatiles of the liverwort *Marchantia polymorpha*. Therefor the test data is a part of that dataset.

## What is it for? What can it do?

The script does a rough data filtering, excluding peaks with a annotated compound probability below a certain threshold (80%) as well as compounds with an annotated biological non viable sum formula. It also filters compounds found in a given blank by retention time. The resulted list can then further be used for analysis and plotting.

## How to

1. Open the script in a new RStudio-Project.
2. Install the packages writexl and readxl and read their libraries (line 21).

		install.packages("readxl")
		install.packages("writexl")

		library(readxl)
		library(writexl)

3. **Save the script on source** (Source on Save).
4. Collect all peak lists in a folder in the project.
5. Make sure you have the path to your blank peak list.
6. *Optional* save the folder path to your sample peak lists as the sample_path variable using hte given syntax.
7. *Optional* save the file path to your blank as the blank_path variable.
8. Use the start_batch_processing function using your paths as arguments in the terminal.

		start_batch_processing(sample_path, blank_path)

## Input format

This script uses xlsx files. One file is used for one sample. The first sheet inhabits an annotated peak list

![](/pictures/peak_input_list.png)


