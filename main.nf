#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// Subworkflows
include { QC } from './workflows/qc'

// Module imports for variant calling
include { BWA_INDEX }     from './modules/bwa_align'
include { BWA_ALIGN }     from './modules/bwa_align'
include { SAMTOOLS_SORT } from './modules/bwa_align'
include { VARIANT_CALL }  from './modules/variant_call'

// Parameters
params.input     = null
params.reference = null
params.outdir    = 'results'
params.qc_only   = false

// Validate inputs
if (!params.input) {
    error "Please provide --input <samples.csv>"
}

// Main workflow
workflow {
    // Parse sample sheet: sample_id, fastq_1, fastq_2
    Channel
        .fromPath(params.input)
        .splitCsv(header: true)
        .map { row -> tuple(row.sample_id, file(row.fastq_1), file(row.fastq_2)) }
        .set { samples_ch }

    // QC workflow (always runs)
    QC(samples_ch)

    // Variant calling (optional)
    if (!params.qc_only && params.reference) {
        ref = file(params.reference)
        BWA_INDEX(ref)
        BWA_ALIGN(samples_ch, BWA_INDEX.out.index)
        SAMTOOLS_SORT(BWA_ALIGN.out.sam)
        VARIANT_CALL(SAMTOOLS_SORT.out.bam, ref)
    }
}
