include { DORADO } from './subworkflows/local/dorado'

params.input_files = null



workflow {
    input_files = Channel.fromPath(params.input_files)
    samplesheet = Channel.fromPath(params.samplesheet)
    fasta = Channel.fromPath(params.fasta).collect() //.collect() ensures that this is a Value channel and will not be consumed when used alongside a queue channel
    barcode_kit = params.barcode_kit
    barcode_both_ends = Channel.of(params.barcode_both_ends).collect()

    println "this is the samplesheet ${params.samplesheet}"
    DORADO(input_files,samplesheet,fasta,barcode_kit,barcode_both_ends)
}

