pipeline {
    agent any

    environment {
        NXF_VER = '25.10.3'
        PATH = "/usr/local/bin:/opt/homebrew/bin:${env.HOME}/.local/bin:${env.PATH}"
    }

    stages {
        stage('Setup') {
            steps {
                sh 'nextflow -version'
            }
        }

        stage('Test QC Pipeline') {
            steps {
                sh 'nextflow run main.nf -profile docker,test --qc_only'
            }
            post {
                success {
                    sh '''
                        test -f results/fastqc/sample_R1_fastqc.html
                        test -f results/multiqc/multiqc_report.html
                    '''
                }
            }
        }

        stage('Test Full Pipeline') {
            steps {
                sh 'rm -rf results work'
                sh 'nextflow run main.nf -profile docker,test'
            }
            post {
                success {
                    sh '''
                        test -f results/alignments/test_sample.sorted.bam
                        test -f results/variants/test_sample.vcf.gz
                    '''
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'results/**/*', allowEmptyArchive: true
            sh 'rm -rf work'
        }
        success {
            echo 'Pipeline tests passed.'
        }
        failure {
            echo 'Pipeline tests failed.'
        }
    }
}
