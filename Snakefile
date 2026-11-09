import os
from pathlib import Path

configfile: "config.yaml"

# Directories
OUT = config["output_dir"]

# MultiQC Path
MULTIQC = "/home/icaramujo/miniconda3/envs/multiqc/bin/multiqc"

# Get sample name
samples_pt = glob_wildcards(
  config["input_dir"]["PT"] + "/{sample}_R1.fastq.gz"
).sample

samples_se = glob_wildcards(
  config["input_dir"]["SE"] + "/{sample}_R1.fastq.gz"
).sample

SAMPLES = list(samples_pt) + list(samples_se)

# Associate samples to folders
SAMPLE_DIR = {}

for sample in samples_pt:
    SAMPLE_DIR[sample] = config["input_dir"]["PT"]

for sample in samples_se:
    if sample in SAMPLE_DIR:
        raise ValueError("Sample name repeated: " + sample)
    SAMPLE_DIR[sample] = config["input_dir"]["SE"]

OUT = config["output_dir"]
THREADS = config["threads"]

rule all:
    input:
        OUT + "/MultiQC_original/multiqc_original.html",
        OUT + "/MultiQC_filtered/multiqc_filtered.html"

# ------------------------------------------
# Original FASTQC
# ------------------------------------------

rule fastqc_original:
    input:
            R1=lambda wc: SAMPLE_DIR[wc.sample] + "/" + wc.sample + "_R1.fastq.gz", 
            R2=lambda wc: SAMPLE_DIR[wc.sample] + "/" + wc.sample + "_R2.fastq.gz"

    output:
         R1_html=OUT + "/FastQC_original/{sample}_R1_fastqc.html",
             R1_zip=OUT + "/FastQC_original/{sample}_R1_fastqc.zip",
             R2_html=OUT + "/FastQC_original/{sample}_R2_fastqc.html",
             R2_zip=OUT + "/FastQC_original/{sample}_R2_fastqc.zip"

    threads: THREADS

    shell:
        """
        mkdir -p {OUT}/FastQC_original

        fastqc \
             {input.R1} {input.R2} \
             --outdir {OUT}/FastQC_original \
             --threads {threads}
        """

# -----------------------------------------------
# ORIGINAL MultiQC
#------------------------------------------------

rule multiqc_original:
    input:
        expand(
            OUT + "/FastQC_original/{sample}_R1_fastqc.html",
            sample=SAMPLES
        ),
        expand(
            OUT + "/FastQC_original/{sample}_R2_fastqc.html",
            sample=SAMPLES
        )

    output:
        OUT + "/MultiQC_original/multiqc_original.html"

    shell:
        """
        mkdir -p {OUT}/MultiQC_original

       {MULTIQC} {OUT}/FastQC_original \
            --outdir {OUT}/MultiQC_original \
            --filename multiqc_original.html \
            --force
        """


# --------------------------------------------------
# FASTP
# --------------------------------------------------

rule fastp:
    input:
        R1=lambda wc: SAMPLE_DIR[wc.sample] + "/" + wc.sample + "_R1.fastq.gz",
        R2=lambda wc: SAMPLE_DIR[wc.sample] + "/" + wc.sample + "_R2.fastq.gz",
        qc_report=OUT + "/MultiQC_original/multiqc_original.html"

    output:
        R1=OUT + "/fastp/{sample}_R1.fastq.gz",
        R2=OUT + "/fastp/{sample}_R2.fastq.gz",
        html=OUT + "/fastp/{sample}_fastp.html",
        json=OUT + "/fastp/{sample}_fastp.json"

    params:
        q=config["fastp"]["qualified_quality_phred"],
        length=config["fastp"]["length_required"],
        cut_front="--cut_front" if config["fastp"]["cut_front"] else "",
        cut_tail="--cut_tail" if config["fastp"]["cut_tail"] else "",
        adapters="--detect_adapter_for_pe" if config["fastp"]["detect_adapter_for_pe"] else "",
        poly_g="--trim_poly_g" if config["fastp"]["trim_poly_g"] else "",
        poly_x="--trim_poly_x" if config["fastp"]["trim_poly_x"] else "",
        low_complexity="--low_complexity_filter" if config["fastp"]["low_complexity_filter"] else ""

    threads: THREADS

    shell:
        """
        mkdir -p {OUT}/fastp

        fastp \
            --in1 {input.R1} \
            --in2 {input.R2} \
            --out1 {output.R1} \
            --out2 {output.R2} \
            --qualified_quality_phred {params.q} \
            --length_required {params.length} \
            --thread {threads} \
            --html {output.html} \
            --json {output.json} \
            {params.cut_front} \
            {params.cut_tail} \
            {params.adapters} \
            {params.poly_g} \
            {params.poly_x} \
            {params.low_complexity}
        """


# --------------------------------------------------
# Filtered FASTQC
# --------------------------------------------------

rule fastqc_filtered:
    input:
        R1=OUT + "/fastp/{sample}_R1.fastq.gz",
        R2=OUT + "/fastp/{sample}_R2.fastq.gz"

    output:
        R1_html=OUT + "/FastQC_filtered/{sample}_R1_fastqc.html",
        R1_zip=OUT + "/FastQC_filtered/{sample}_R1_fastqc.zip",
        R2_html=OUT + "/FastQC_filtered/{sample}_R2_fastqc.html",
        R2_zip=OUT + "/FastQC_filtered/{sample}_R2_fastqc.zip"

    threads: THREADS

    shell:
        """
        mkdir -p {OUT}/FastQC_filtered

        fastqc \
            {input.R1} {input.R2} \
            --outdir {OUT}/FastQC_filtered \
            --threads {threads}
        """


# --------------------------------------------------
# Final MULTIQC
# --------------------------------------------------

rule multiqc_filtrado:
    input:
        expand(
            OUT + "/FastQC_filtered/{sample}_R1_fastqc.html",
            sample=SAMPLES
        ),
        expand(
            OUT + "/FastQC_filtered/{sample}_R2_fastqc.html",
            sample=SAMPLES
        ),
        expand(
            OUT + "/fastp/{sample}_fastp.json",
            sample=SAMPLES
        )

    output:
        OUT + "/MultiQC_filtered/multiqc_filtered.html"

    shell:
        """
        mkdir -p {OUT}/MultiQC_filtered

       {MULTIQC} \
            {OUT}/FastQC_filtered \
            {OUT}/fastp \
            --outdir {OUT}/MultiQC_filtered \
            --filename multiqc_filtered.html \
            --force
        """

