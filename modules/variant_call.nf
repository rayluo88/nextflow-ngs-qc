process VARIANT_CALL {
    tag "$sample_id"
    container 'quay.io/biocontainers/bcftools:1.21--h8b25389_0'
    publishDir "${params.outdir}/variants", mode: 'copy'

    input:
    tuple val(sample_id), path(bam), path(bai)
    path(reference)

    output:
    tuple val(sample_id), path("${sample_id}.vcf.gz"), emit: vcf

    script:
    """
    bcftools mpileup -f ${reference} ${bam} \
        | bcftools call -mv -Oz -o ${sample_id}.vcf.gz
    bcftools index ${sample_id}.vcf.gz
    """
}
