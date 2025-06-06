#Team 6: Paula, Sadiksha**
  
# 🧬 Capstone Project: R-based Mass Spectrometry Proteomics Workflow
  
#This document provides a step-by-step guide for your capstone project on analyzing proteomics data using R.

---
  
## 🔁 Workflow Overview
  ### 1. 📁 Dataset Acquisition  
  #**Input:** PRIDE PXD Identifier  
 
#(*Example: `PXD0123456`, accessible via [PRIDE](https://www.ebi.ac.uk/pride/)*)

#Use the `rpx` package to access metadata and download a dataset that includes `.mzID` files from a published study.
library(rpx)
px <- PXDataset("PXD056514")  # Create a PXDataset object for the dataset with ID "PXD056514"
pxfiles(px) ## Retrieve and display a list of all files associated with the PXDataset object 'px'

---
  
### 2. 🧱 PSM Object Creation & Preprocessing  
#**Goal:** Generate a PSM (Peptide-Spectrum Match) object from `.mzID` files  
 
#- Convert `.mzID` files into `PSM` objects
# Assess:
# Number of decoy hits
# Score distributions
# PSM rank
# Apply filtering based on FDR or identification score

library(PSMatch)
library(rpx)
library(MSnID)

# Step 1: Access the dataset
files <- pxfiles(px) #Retrieve and display a list of all files associated with the PXDataset object 'px'
mzid_files <- pxget(px, grep("mzid", pxfiles(px))[1]) #Identify the .mzID files from the retrieved files
 #only doing 1 for test. how to do all
basename(mzids)
library("MSnID")
msnid <- MSnID(".")
msnid <- read_mzIDs(msnid, mzids)
id <- psms(msnid)
id <- psms(px)


sum(id$isDecoy)
table(id$isDecoy) #false no decoy
# Score distributions
score_distribution <- summary(id$`Mascot:score`)
print(score_distribution)
#Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#0.00    3.05    6.17   11.81   11.36  145.52 

# PSM rank
psm_rank_distribution <- table(id$rank)
print(psm_rank_distribution)
#   1    2    3    4    5    6    7    8    9   10 
#9137 5396 4268 3477 2972 2525 2149 1940 1698 1556 

#Apply filtering based on FDR or identification score
threshold <- 0.01  # Set your FDR or score threshold
#I dont see fdr in this data, also which score?

#i dont know which score to use
library(ggplot2)
ggplot(id, aes(x =  `Mascot:score`,
               colour = isDecoy)) +
  geom_density()

---
  
### 3. 🧬 Protein & Peptide Identification  
# **Goal:** Determine identified peptides and proteins  
#Count the number of identified peptides and proteins
#Review peptide-to-protein mapping:
#Razor proteins
#Protein groups

identified_peptides <- unique(id$peptide)  # Get unique peptides
length(identified_peptides)
#23785
identified_proteins <- unique(id$accession)  # Get unique protein accessions 
length(identified_proteins)
#8055

# Create a mapping of peptides to proteins
peptide_to_protein_mapping <- table(id$peptide, id$accession)

library(dplyr)
razor_proteins <- id %>%
  group_by(peptide) %>%  # Group by peptide
  filter(!is.na(accession)) %>%  # Filter out NA accessions
  slice(which.max(`Mascot:score`)) %>%  # Select the highest-scoring protein
  ungroup() %>%  # Ungroup to return to the original data frame structure
  select(peptide, Leading.razor.protein = accession)  # Select relevant columns
#For all 23785 peptides
table(razor_proteins$Leading.razor.protein)
length(unique(razor_proteins$Leading.razor.protein)) #7716 proteins. There are so many. may be there can't be so many razor proteins. are these protein groups then?

#Protein groups (based on unique accessions)
proteins <- unique(id$accession)  # Extract unique protein accessions

---
  
### 4. 🔄 QFeature Aggregation (Optional)  
# **Goal:** Use quantification data if available  
  
#Use `aggregateFeatures()` from the `QFeatures` package to aggregate:
  #PSMs ➡️ Peptides ➡️ Proteins

library(QFeatures)
library(dplyr)  
qfeatures <- QFeatures(list(PSM = SummarizedExperiment(assays = list(lognorm_peptides = as.matrix(id)))))
# Assuming 'peptide' is the column with peptide sequences and 'Mascot:score' is the scoring metric

rowData(qfeatures[["PSM"]])
qfeatures[["PSM"]]
data("b1370p17_S9_Tot_Prot_P31_FRAX_24h_1000nM_3.RAW.-1.mgf")

qfeatures <- aggregateFeatures(qfeatures,
                               i = "PSM",  # Input assay
                               name = "Peptides",  # Name of the new aggregated feature
                               fcol = "peptide",  # Column containing peptide sequences
                               fun = colMeans,  # Aggregation function (mean of scores, for example)
                               na.rm = TRUE)

library(MSnbase)



---
  
  ### 5. 🧼 Normalization & Imputation (Optional)  
  **Goal:** Correct for technical variation and handle missing values  
↓  
- Normalize using `normalize()` or `normalize_vsn()`
- Impute missing values with `impute()`

---
  
  ### 6. 🧪 Protein Inference & Quantification (Optional)  
  **Goal:** Summarize and quantify proteins  
↓  
- Aggregate peptide-level intensities into protein-level quantities
- Optionally annotate protein IDs using external databases (e.g., UniProt)

---
  
  ### 7. 📊 Statistical Analysis (Optional)  
  **Goal:** Identify differentially abundant proteins  
↓  
- Perform statistical testing (e.g., using `test_diff()`)
- Filter by:
  - Log2 fold-change
- Adjusted p-value (e.g., FDR < 0.05)

---
  
  ### 8. 📈 Visualization & Export (Optional)  
  **Goal:** Visualize data for interpretation  
↓  
- Create visual summaries:
  - PCA plots
- Volcano plots
- Heatmaps  
- Use packages such as `ggplot2`, `DEP`, or `limma`

---
  
  ### 9. 📖 Comparison with Published Results  
  **Goal:** Benchmark your findings  
↓  
Create a comparison table including:
  - Number of spectra identified
- Number of peptides and proteins
- Key figures or results (if available)
- Comments on reproducibility

---
  
  ### 10. 📝 Final Report & Interpretation  
  **Goal:** Reflect on your analysis  
↓  
Submit the following:
  - Source code (R script or RMarkdown) in your team folder
- A 1–2 page report that includes:
  - Background of the dataset and study
- Summary table of key results
- Discussion:
  > Why do your results match or differ from the original publication?
  
  ---
  
  ✅ **Tip:** Convert your `.Rmd` into a clean `README.md` using `knitr::knit("README.Rmd")`.
