nextflow.enable.dsl=2

// Paths relative to workflow/
params.sra    = "$baseDir/../raw/*/*.sra"
params.genome = "$baseDir/../reference/ecoli.fa"
params.gtf    = "$baseDir/../reference/GCF_000005845.2_ASM584v2_genomic.gff.gz"
params.bin    = "$baseDir/../bin"
params.meta   = "$baseDir/../metadata.csv"

workflow {

    sra_ch = Channel.fromPath(params.sra, checkIfExists: true)

    fastq_ch = FASTQ_CONVERT(sra_ch)

   qc_ch = FASTQC(fastq_ch)
   
   // 🔥 FIX: remove extra FASTQC outputs before ALIGN
   qc_trimmed = qc_ch.map { id, r1, r2, zip, html -> tuple(id, r1, r2) }
   
   genome_ch = Channel.value(file(params.genome))
   
   // Build index once
   index_ch = BUILD_INDEX(genome_ch)
   
   bam_ch = ALIGN(qc_trimmed, index_ch)

    // Extract BAM paths
    bam_files = bam_ch.map { id, bam -> bam }

    gtf_ch = Channel.fromPath(params.gtf, checkIfExists: true)

    counts_ch = COUNT(bam_files.collect(), gtf_ch)

    meta_ch = Channel.fromPath(params.meta, checkIfExists: true)

    deseq_ch = DESEQ2(counts_ch, meta_ch)

    MULTIQC()
}

process FASTQ_CONVERT {

    input:
    path sra

    output:
    tuple val(sra.baseName),
          path("${sra.baseName}_1.fastq.gz"),
          path("${sra.baseName}_2.fastq.gz")

    script:
    """
    ID=\$(basename ${sra} .sra)

    fasterq-dump ${sra} --split-files -e 6 -O .

    mv \${ID}.sra_1.fastq \${ID}_1.fastq
    mv \${ID}.sra_2.fastq \${ID}_2.fastq

    gzip \${ID}_1.fastq
    gzip \${ID}_2.fastq
    """
}

process FASTQC {

    publishDir "$baseDir/../results/fastqc", mode: 'copy'

    input:
    tuple val(id), path(r1), path(r2)

    output:
    tuple val(id), path(r1), path(r2), path("*_fastqc.zip"), path("*_fastqc.html")

    script:
    """
    fastqc ${r1} ${r2}
    """
}

process BUILD_INDEX {

    publishDir "$baseDir/../results/index", mode: 'copy'

    input:
    path genome

    output:
    path "ecoli_index.*.ht2"

    script:
    """
    hisat2-build ${genome} ecoli_index
    """
}

process ALIGN {

    publishDir "$baseDir/../results/alignment", mode: 'copy'

    input:
    tuple val(id), path(r1), path(r2)
    path index_files

    output:
    tuple val(id), path("${id}.bam")

    script:
    """
    hisat2 -x ecoli_index -1 ${r1} -2 ${r2} \
        | samtools view -bS - > ${id}.bam

    # Free disk
    rm -f ${r1} ${r2}
    """
}

process COUNT {

    publishDir "$baseDir/../results/counts", mode: 'copy'

    input:
    path bam_files
    path gtf

    output:
    path "counts.txt"

    script:
    """
    featureCounts -a ${gtf} \
                  -t CDS \
                  -g ID \
                  -p \
                  --countReadPairs \
                  -o counts.txt \
                  ${bam_files.join(' ')}
    """
}

process DESEQ2 {

    publishDir "$baseDir/../results/deseq2", mode: 'copy'

    input:
    path counts
    path meta

    output:
    path "deseq2_results.csv"
    path "gene_rank.rnk"

    script:
    """
    python ${params.bin}/pydeseq2_analysis.py ${counts} ${meta}
    """
}

process MULTIQC {

    publishDir "$baseDir/../results/multiqc", mode: 'copy'

    output:
    path "multiqc_report.html"
    path "multiqc_data"

    script:
    """
    multiqc $baseDir/../results -o .

    """
}
