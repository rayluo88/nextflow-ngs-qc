process MULTIQC {
    container 'quay.io/biocontainers/multiqc:1.25.2--pyhdfd78af_0'
    publishDir "${params.outdir}/multiqc", mode: 'copy'

    input:
    path(reports)

    output:
    path("multiqc_report.html"), emit: report
    path("multiqc_report_data"), emit: data

    script:
    """
    multiqc . --filename multiqc_report
    """
}
