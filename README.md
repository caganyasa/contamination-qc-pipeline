# Contamination QC Pipeline

This repository contains a small bioinformatics QC pipeline developed to detect contamination and sample inconsistencies in next generation sequencing (NGS) BAM files. The workflow combines two independent tools, VerifyBamID2 and NGSTroubleFinder, and produces a single summarized QC report.

The motivation behind this pipeline is straightforward. Contamination detection based on a single algorithm can sometimes miss problematic samples or produce ambiguous results. By combining population SNP based contamination estimation (VerifyBamID2) with pileup based QC metrics (NGSTroubleFinder), the pipeline provides a more reliable and interpretable quality control step for sequencing data.

The pipeline accepts a directory containing BAM files, processes each sample, runs both tools, and generates a combined Excel summary file highlighting samples that exceed predefined contamination thresholds.

This repository intentionally does not contain any real sequencing data, BAM files, or patient identifiers. Only the pipeline logic and a demonstration output file are included.

---

Pipeline overview

The pipeline processes BAM files in several steps.

First, VerifyBamID2 is executed for every BAM file. This tool estimates contamination using allele frequencies from a reference SNP panel. The key metric extracted from VerifyBamID2 output is the FREEMIX score, which represents the estimated contamination fraction.

Next, the pipeline prepares the BAM files for NGSTroubleFinder. In some sequencing workflows chromosome naming conventions may differ (for example chr1 vs 1). The script normalizes BAM headers when necessary and prepares a metadata file describing each sample. NGSTroubleFinder then performs a pileup based analysis across known SNP positions. It estimates contamination, evaluates heterozygosity patterns, checks sex consistency and can detect potential sample relatedness within a cohort.

After both tools finish, a Python step collects the results and merges them into a single summary table. The final Excel file contains contamination scores from both tools together with inferred sex information. Samples exceeding contamination thresholds are highlighted automatically.

---

Directory structure

The repository is intentionally minimal and contains only the files required to run the pipeline.

contamination_qc  
run_qc.sh  
README.md  
.gitignore  
scripts/  
examples/demo_contamination_summary.xlsx  

The examples directory contains a demonstration QC report showing the structure of the final output without exposing real sample identifiers.

---

Software requirements

The pipeline was designed to run in a Linux environment and is easiest to install using conda.

Required software includes:

VerifyBamID2  
samtools  
Python 3.10  
pandas  
openpyxl  
NGSTroubleFinder

---

Installation

If conda is not installed on your system, first install Miniconda from the official website.

https://docs.conda.io/en/latest/miniconda.html

After installation reload your shell so the conda command becomes available.

Create a new environment for the pipeline.

conda create -n qc_env python=3.10  
conda activate qc_env  

Install the required bioinformatics tools.

conda install -c bioconda verifybamid2 samtools  

Install the Python dependencies used for generating the summary report.

pip install pandas openpyxl  

NGSTroubleFinder must be installed from its GitHub repository.

git clone https://github.com/BCM-HGSC/NGS-Trouble-Finder.git  
cd NGS-Trouble-Finder  
pip install .

Once installation is complete the command ngsTroubleFinder should be available in the terminal.

---

Required reference resources

VerifyBamID2 requires a reference genome and a SNP panel.

A typical setup uses a reference FASTA file such as hg38 together with an index generated using samtools faidx.

The SNP panel used by VerifyBamID2 is typically derived from the 1000 Genomes Project and contains allele frequency information for known variants.

These large reference resources are not included in the repository and must be obtained separately.

---

Running the pipeline

To run the workflow simply execute the main script.

bash run_qc.sh

The script will prompt the user to provide the path to the directory containing BAM files. All BAM files within the directory will be processed automatically.

During execution the pipeline creates an output directory called qc_results. Inside this directory the raw outputs from VerifyBamID2 and NGSTroubleFinder are stored together with the final summary report.

The most important output file produced by the pipeline is contamination_summary.xlsx. This Excel file merges contamination metrics from both tools and highlights samples that may require further inspection.

---

Contamination thresholds

The pipeline applies simple threshold values to flag potentially contaminated samples.

For VerifyBamID2 a FREEMIX value greater than or equal to 0.02 is considered suspicious.

For NGSTroubleFinder a contamination value greater than or equal to 0.05 is typically flagged.

These thresholds can be adjusted depending on the sequencing platform, capture kit or internal laboratory QC policies.

---

Example output

An anonymized example report is provided in the examples directory.

examples/demo_contamination_summary.xlsx

The sample names in this file are randomized and do not correspond to real sequencing data. The structure of the file matches the report produced by the pipeline.

The report contains four columns: Sample name, VerifyBamID2 contamination score, NGSTroubleFinder contamination score and inferred sex information. Samples exceeding contamination thresholds are highlighted automatically.

---

Data privacy note

This repository does not contain real sequencing data or patient related identifiers. BAM files, reference genomes, SNP panels and internal QC results are intentionally excluded.

The goal of the repository is to demonstrate the pipeline structure and provide reproducible QC logic without exposing sensitive data.

---

Tools and credits

This pipeline integrates two open source tools developed by the genomics community.

VerifyBamID2  
https://github.com/Griffan/VerifyBamID  

VerifyBamID2 is used for contamination estimation based on population allele frequencies. The pipeline extracts the FREEMIX contamination metric from VerifyBamID2 outputs.

NGSTroubleFinder  
https://github.com/BCM-HGSC/NGS-Trouble-Finder  

NGSTroubleFinder performs pileup based quality control checks including contamination estimation, sex inference and relatedness detection across samples.

If you use this pipeline in research or production workflows, please cite the original tools accordingly.

---

Author

Çağan Yasa  
Bioinformatics Specialist

The pipeline was developed as part of routine NGS quality control workflows used in sequencing environments.
