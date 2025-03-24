process CONVERT_TO_FASTQ {
    input:
    tuple val(meta), path(file)
    output:
    tuple val(meta), path("*fastq.gz"), emit:fastq


    script:
    """
    samtools bam2fq $file > "${meta.id}.fastq.gz"
    """

}
