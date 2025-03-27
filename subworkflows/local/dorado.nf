include { DORADO_DEMULTIPLEXING } from '../../modules/local/dorado/demultiplexing'
include { DORADO_ALIGNER } from '../../modules/local/dorado/aligner'
include { CHOPPER } from '../../modules/nf-core/chopper'

workflow DORADO {
    take:
    input_files //path to dir containing fastqs/ubams
    samplesheet
    reference_fasta
    barcode_kit
    barcode_both_ends

    main:
    //TODO make demux optional
    //Demultiplexing
    DORADO_DEMULTIPLEXING(samplesheet, input_files, barcode_kit, barcode_both_ends)
    sample_fastq = DORADO_DEMULTIPLEXING.out.fastq //list of all sample fastqs

    /*
    * convert sample_fastq into [meta, fastq]
    */

    //create meta maps per sample from the samplesheet
    meta = samplesheet.splitCsv(header: true)
                .map { row -> 
                    def meta = [
                        id: row.sample_id, 
                        position: row.position_id, 
                        flow_cell: row.flow_cell_id, 
                        kit: row.kit, 
                        experiment: row.experiment_id, 
                        barcode: row.barcode, 
                        alias: row.alias
                    ]
                    return [row.alias, meta]  // Return metadata and alias for matching
                }//.view()

    //restructure fastq channel into alias, fastq 
    sample_fastq_alias = sample_fastq
        .flatMap { it } //flatten list
        .map { file -> 
            def alias = file.baseName.replaceAll(/.fastq/,"")
                                     .replaceAll(/unknown_run_id_/,"")
            return [alias, file]
    }//.view()

    //join sample fastqs and meta maps using alias as matching key, and remap to format as [meta,file]
    sample_fastq_ch = meta.join(sample_fastq_alias)
                          .map { alias, meta, file -> [meta, file]}
                          .view()

    //chopper fastq trimming
    CHOPPER(sample_fastq_ch, reference_fasta)
    sample_clean_fastq = CHOPPER.out.fastq

    DORADO_ALIGNER(sample_clean_fastq, reference_fasta)
    sample_bams = DORADO_ALIGNER.out.bam //{[meta1, bam1], [meta2, bam2]}

    emit:
    sample_bams
}
