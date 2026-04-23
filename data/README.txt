# Dataset Instructions

This directory is intended for input data required to run the RNA-seq pipeline.

---

## Supported Input Types

### 1. SRA Files (Recommended)

Place SRA files in subdirectories as shown below:

data/
SRR12922090/
SRR12922090.sra
SRR12922091/
SRR12922091.sra
SRR12922098/
SRR12922098.sra

---

## Downloading SRA Data

You can download SRA files from NCBI:

https://www.ncbi.nlm.nih.gov/sra

### Example using SRA Toolkit:

prefetch SRR12922090
prefetch SRR12922091
prefetch SRR12922098

---

## Alternative: FASTQ Files

If using FASTQ files instead of SRA:

data/
sample_1.fastq.gz
sample_2.fastq.gz

Paired-end reads must follow naming convention:
*_1.fastq.gz and *_2.fastq.gz

---

## Running the Pipeline

Example command:

nextflow run main.nf 
--sra "data/*/*.sra" 
--genome reference/ecoli.fa 
--gtf reference/GCF_000005845.2_ASM584v2_genomic.gff.gz 
--meta metadata.csv

---

## Notes

* Ensure file names match sample IDs in metadata.csv
* Do not store large datasets in the GitHub repository
* Only small test data should be included for demonstration

---
