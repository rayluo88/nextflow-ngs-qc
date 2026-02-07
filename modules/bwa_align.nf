process BWA_INDEX {
    container 'quay.io/biocontainers/bwa:0.7.18--he4a0461_1'

    input:
    path(reference)

    output:
    tuple path(reference), path("${reference}.*"), emit: index

    script:
    """
    bwa index ${reference}
    """
}

process BWA_ALIGN {
    tag "$sample_id"
    container 'quay.io/biocontainers/bwa:0.7.18--he4a0461_1'

    input:
    tuple val(sample_id), path(fastq_1), path(fastq_2)
    tuple path(reference), path(index_files)

    output:
    tuple val(sample_id), path("${sample_id}.sam"), emit: sam

    script:
    """
    bwa mem -t ${task.cpus} -R "@RG\\tID:${sample_id}\\tSM:${sample_id}\\tPL:ILLUMINA" \
        ${reference} ${fastq_1} ${fastq_2} > ${sample_id}.sam
    """
}

process SAMTOOLS_SORT {
    tag "$sample_id"
    container 'quay.io/biocontainers/samtools:1.21--h50ea8bc_0'
    publishDir "${params.outdir}/alignments", mode: 'copy'

    input:
    tuple val(sample_id), path(sam)

    output:
    tuple val(sample_id), path("${sample_id}.sorted.bam"), path("${sample_id}.sorted.bam.bai"), emit: bam

    script:
    """
    samtools sort -@ ${task.cpus} -o ${sample_id}.sorted.bam ${sam}
    samtools index ${sample_id}.sorted.bam
    """
}
