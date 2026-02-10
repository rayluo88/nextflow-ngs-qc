# nextflow-ngs-qc

[![CI](https://github.com/rayluo88/nextflow-ngs-qc/actions/workflows/ci.yml/badge.svg)](https://github.com/rayluo88/nextflow-ngs-qc/actions/workflows/ci.yml)
[![Nextflow](https://img.shields.io/badge/Nextflow-%E2%89%A522.10-blue?logo=nextflow)](https://www.nextflow.io/)
[![Docker](https://img.shields.io/badge/Docker-ready-blue?logo=docker)](https://www.docker.com/)

A modular NGS quality control and variant calling pipeline in Nextflow DSL2. It takes paired-end FASTQ files, runs FastQC and MultiQC for quality assessment, and optionally extends to alignment with BWA-MEM and variant calling with bcftools. Every tool runs in its own versioned Docker container for reproducibility, and it has CI/CD with both GitHub Actions and Jenkins. Built with [nf-core](https://nf-co.re/) conventions.

---

## Pipeline Overview

```
                         ┌─────────────────┐
                         │  Input FASTQs   │
                         │  (paired-end)   │
                         └────────┬────────┘
                                  │
                    ┌─────────────┴──────────────┐
                    ▼                            ▼
            ┌──────────────┐              ┌──────────────┐
            │   FastQC     │              │  BWA Index   │
            │   (per-sample│              │  (reference) │
            │    QC)       │              └──────┬───────┘
            └──────┬───────┘                     │
                   │                             ▼
                   ▼                      ┌──────────────┐
            ┌──────────────┐              │  BWA-MEM     │
            │   MultiQC    │              │  (alignment) │
            │  (aggregate) │              └──────┬───────┘
            └──────────────┘                     │
                                                 ▼
           ─ ─ ─ ─ ─ ─ ─ ─ ─              ┌──────────────┐
           --qc_only stops here           │  SAMtools    │
           ─ ─ ─ ─ ─ ─ ─ ─ ─              │  (sort+index)│
                                          └──────┬───────┘
                                                 │
                                                 ▼
                                          ┌──────────────┐
                                          │  bcftools    │
                                          │  (call)      │
                                          └──────────────┘
```

## Quick Start

```bash
# Clone the repository
git clone https://github.com/rayluo88/nextflow-ngs-qc.git
cd nextflow-ngs-qc

# Run with bundled test data — QC only
nextflow run main.nf -profile docker,test --qc_only

# Run with bundled test data — full pipeline (QC + variant calling)
nextflow run main.nf -profile docker,test
```

### Requirements

| Dependency | Version |
|------------|---------|
| [Nextflow](https://www.nextflow.io/) | >= 22.10 |
| [Docker](https://www.docker.com/) or [Singularity](https://sylabs.io/) | any recent |
| Java | >= 11 |

---

## Usage

### Input

Provide a CSV sample sheet with three columns:

```csv
sample_id,fastq_1,fastq_2
sample_A,data/sample_A_R1.fastq.gz,data/sample_A_R2.fastq.gz
sample_B,data/sample_B_R1.fastq.gz,data/sample_B_R2.fastq.gz
```

### Run Modes

**QC only** — runs FastQC and MultiQC:

```bash
nextflow run main.nf \
    --input samples.csv \
    --qc_only \
    -profile docker
```

**Full pipeline** — QC + alignment + variant calling:

```bash
nextflow run main.nf \
    --input samples.csv \
    --reference genome.fa \
    -profile docker
```

### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--input` | *required* | Path to sample sheet CSV |
| `--reference` | — | Reference genome FASTA (required for variant calling) |
| `--outdir` | `results` | Output directory |
| `--qc_only` | `false` | Skip alignment and variant calling |

### Profiles

| Profile | Description |
|---------|-------------|
| `docker` | Run with Docker containers |
| `singularity` | Run with Singularity containers |
| `test` | Use bundled test data (SARS-CoV-2, 100 read pairs) |

Profiles can be combined: `-profile docker,test`

---

## Output

```
results/
├── fastqc/                  # Per-sample FastQC HTML reports and ZIP archives
├── multiqc/                 # Aggregated MultiQC report across all samples
│   ├── multiqc_report.html
│   └── multiqc_report_data/
├── alignments/              # Sorted, indexed BAM files (full pipeline only)
│   ├── <sample>.sorted.bam
│   └── <sample>.sorted.bam.bai
└── variants/                # Compressed VCF files (full pipeline only)
    └── <sample>.vcf.gz
```

---

## Pipeline Architecture

### Modular DSL2 Design

Each bioinformatics tool is encapsulated as an independent Nextflow process, following [nf-core module conventions](https://nf-co.re/docs/contributing/modules):

```
modules/
├── fastqc.nf          # Read-level quality control
├── multiqc.nf         # Multi-sample QC aggregation
├── bwa_align.nf       # BWA indexing, alignment, SAMtools sorting
└── variant_call.nf    # bcftools mpileup + call
```

### Containers

All processes run in versioned BioContainers from [Quay.io](https://quay.io/organization/biocontainers):

| Process | Tool | Version | Container |
|---------|------|---------|-----------|
| FASTQC | FastQC | 0.12.1 | `quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0` |
| MULTIQC | MultiQC | 1.25.2 | `quay.io/biocontainers/multiqc:1.25.2--pyhdfd78af_0` |
| BWA_INDEX / BWA_ALIGN | BWA | 0.7.18 | `quay.io/biocontainers/bwa:0.7.18--he4a0461_1` |
| SAMTOOLS_SORT | SAMtools | 1.21 | `quay.io/biocontainers/samtools:1.21--h50ea8bc_0` |
| VARIANT_CALL | bcftools | 1.21 | `quay.io/biocontainers/bcftools:1.21--h8b25389_0` |

### Testing with nf-test

Module-level and workflow-level tests using [nf-test](https://www.nf-test.com/):

```bash
# Run all tests
nf-test test

# Run a specific test
nf-test test tests/modules/fastqc.nf.test
```

| Test | Scope | What it verifies |
|------|-------|------------------|
| `tests/modules/fastqc.nf.test` | Process | FastQC produces HTML + ZIP reports |
| `tests/modules/bwa_align.nf.test` | Process | BWA index creates all index files |
| `tests/workflows/full_pipeline.nf.test` | Pipeline | Full run produces QC, BAM, and VCF outputs |
| `tests/workflows/qc_only.nf.test` | Pipeline | QC-only mode skips alignment and variant calling |

### CI/CD

- **GitHub Actions CI** — Automated testing on push/PR ([`.github/workflows/ci.yml`](.github/workflows/ci.yml))
- **GitHub Actions CD** — Automated releases on version tags; tests must pass before release is created ([`.github/workflows/release.yml`](.github/workflows/release.yml))
- **Jenkins CI** — Declarative pipeline for on-premise CI ([`Jenkinsfile`](Jenkinsfile))

**Creating a release:**

```bash
git tag -a v1.0.0 -m "v1.0.0 - Initial release"
git push origin v1.0.0
# → Release workflow runs tests → creates GitHub Release automatically
```

---

## Test Data

Bundled SARS-CoV-2 Illumina paired-end reads (100 read pairs, ~30kb genome) from [nf-core/test-datasets](https://github.com/nf-core/test-datasets/tree/modules/data/genomics/sarscov2). See [`test_data/README.md`](test_data/README.md) for provenance details.

---

## Project Structure

```
nextflow-ngs-qc/
├── main.nf                 # Pipeline entry point
├── nextflow.config         # Parameters, profiles, resource defaults
├── Jenkinsfile             # Jenkins declarative pipeline
├── modules/                # Individual tool processes
│   ├── fastqc.nf
│   ├── multiqc.nf
│   ├── bwa_align.nf
│   └── variant_call.nf
├── workflows/
│   └── qc.nf              # QC subworkflow (FastQC → MultiQC)
├── tests/                  # nf-test module and workflow tests
│   ├── modules/
│   └── workflows/
├── nf-test.config          # nf-test configuration
├── test_data/              # Bundled test FASTQ + reference
├── conf/                   # Additional config files
├── .github/workflows/      # GitHub Actions CI + CD (release)
└── README.md
```

## License

MIT
