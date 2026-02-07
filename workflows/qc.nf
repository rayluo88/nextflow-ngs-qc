include { FASTQC }  from '../modules/fastqc'
include { MULTIQC } from '../modules/multiqc'

workflow QC {
    take:
    samples_ch  // tuple(sample_id, fastq_1, fastq_2)

    main:
    FASTQC(samples_ch)
    MULTIQC(FASTQC.out.reports.collect())

    emit:
    fastqc_reports = FASTQC.out.reports
    multiqc_report = MULTIQC.out.report
}
