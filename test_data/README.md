# Test Data

## Source

Test data from [nf-core/test-datasets](https://github.com/nf-core/test-datasets/tree/modules/data/genomics/sarscov2) (SARS-CoV-2 Illumina paired-end reads).

| File | Description | Source |
|------|-------------|--------|
| `sample_R1.fastq.gz` | Forward reads (100 paired-end, 150bp) | `data/genomics/sarscov2/illumina/fastq/test_1.fastq.gz` |
| `sample_R2.fastq.gz` | Reverse reads (100 paired-end, 150bp) | `data/genomics/sarscov2/illumina/fastq/test_2.fastq.gz` |
| `genome.fa` | SARS-CoV-2 reference genome (~30kb) | `data/genomics/sarscov2/genome/genome.fasta` |
| `genome.fa.fai` | Reference index | `data/genomics/sarscov2/genome/genome.fasta.fai` |
| `samples.csv` | Sample sheet for pipeline input | Generated |

## Why SARS-CoV-2?

Small genome (~30kb) makes it ideal for fast CI testing. Same data used by nf-core modules for automated testing.
