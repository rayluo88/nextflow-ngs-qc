process FASTQC {
    tag "$sample_id"
    container 'quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0'
    publishDir "${params.outdir}/fastqc", mode: 'copy'

    input:
    tuple val(sample_id), path(fastq_1), path(fastq_2)

    output:
    path("*_fastqc.{zip,html}"), emit: reports

    script:
    """
    fastqc --threads ${task.cpus} ${fastq_1} ${fastq_2}
    """
}
