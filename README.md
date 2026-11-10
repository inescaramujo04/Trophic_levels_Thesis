# Trophic_levels_Thesis
This repository contains scripts and configuration files developed for the organization of sequencing samples and the quality control (QC) of 16S rRNA gene amplicon sequencing data from aquatic invertebrates collected in freshwater ponds in Portugal and Sweden.
The purpose of this workflow is to organize the sequencing data and assess read quality before downstream microbiome analysis.

## Sample organization - sample_mapping.py
The Python script processes the sample metadata stored in Excel files and generates tab-separated mapping files associating sequencing IDs with the corresponding sample names.

The script requires:

•	Ponds_metagenomic samples.xlsx: contains the general sample information, including the sequencing IDs.

•	1372_8_Sample_information_P*.xlsx: contains the sequencing information for the different sequencing plates.

The script performs the following operations:

1.	Reads the general sample metadata.

2.	Identifies the samples belonging to the pond study.

3.	Reads the sequencing information from the different plate files.

4.	Matches sequencing IDs with their corresponding sample names.

5.	Generates tab-separated mapping files containing the sequencing ID and sample name.

Each mapping file generated contains two columns, sample names are restricted to letters, numbers and underscores to ensure compatibility with downstream bioinformatics tools.

### Requirements

Install the required Python packages:
pip install pandas openpyxl

### Execution

Run the script using: python sample_mapping.py

Make sure the Excel input files are available in the expected Documentos directory.

## Quality control workflow

### Snakemake - Snakefile

The quality control pipeline is implemented using Snakemake, a workflow management system that automates bioinformatics tasks based on input and output dependencies.
The workflow processes paired-end FASTQ files from samples collected in Portugal (PT) and Sweden (SE).

Workflow overview

The pipeline consists of the following steps:

1.	FastQC – Raw reads: assesses the quality of the original sequencing reads.

2.	MultiQC – Raw reads: aggregates the FastQC reports into a single report.

3.	fastp – Read preprocessing: performs quality filtering and read preprocessing.

4.	FastQC – Filtered reads: assesses the quality of the processed reads.

5.	MultiQC – Filtered reads: aggregates the FastQC reports generated after preprocessing.

Input data

The input FASTQ files must be paired-end and compressed in .fastq.gz format.
The sample names must be consistent with the naming convention defined in the Snakefile.

Configuration file: config.yaml

The config.yaml file contains the parameters required to execute the workflow.
The workflow generates the following directory structure:
The MultiQC HTML reports allow the comparison of sequencing quality before and after preprocessing.
The fastp reports also provide information about the filtering process, including read counts and trimming statistics.

## Software requirements

The tools that are necessary  to run the quality control workflow are: Snakemake, FastQC, MultiQC and fastp.

These tools must be installed and accessible in the execution environment.

## Running the quality control pipeline

Step 1 – Activate the environment

Activate the Conda environment containing Snakemake and the required dependencies:

conda activate snakemake

Make sure FastQC, MultiQC and fastp are also available in the environment or accessible through their executable paths.

Step 2 – Navigate to the working directory

cd ~/dados_tese

Step 3 – Test the workflow

Before execution, perform a dry run to check the workflow and its dependencies:

snakemake -n --cores 4

Step 4 – Execute the workflow

If the dry run completes successfully, execute the pipeline:

snakemake --cores 4

Snakemake automatically determines the execution order based on the rules and their dependencies.

Step 5 – Inspect the reports

After execution, open the generated MultiQC HTML reports in a web browser:

•	Quality_Control/MultiQC_original/multiqc_original.html

•	Quality_Control/MultiQC_filtrado/multiqc_filtrado.html

These reports can be used to assess sequencing quality and compare the results before and after filtering.
