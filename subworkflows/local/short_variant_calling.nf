/*
 * Short variant calling test
 */

include { MEDAKA_VARIANT                        } from '../../modules/local/medaka_variant'
include { TABIX_BGZIP as MEDAKA_BGZIP_VCF       } from '../../modules/nf-core/tabix/bgzip/main'
include { TABIX_TABIX as MEDAKA_TABIX_VCF       } from '../../modules/nf-core/tabix/tabix/main'
include { TABIX_TABIX as DEEPVARIANT_TABIX_VCF  } from '../../modules/nf-core/tabix/tabix/main'
include { TABIX_TABIX as DEEPVARIANT_TABIX_GVCF } from '../../modules/nf-core/tabix/tabix/main'
include { PEPPER_MARGIN_DEEPVARIANT             } from '../../modules/local/pepper_margin_deepvariant'
include { DEEPVARIANT_RUNDEEPVARIANT } from '../../modules/nf-core/deepvariant/rundeepvariant/main'

workflow SHORT_VARIANT_CALLING {

    take:
    ch_view_sortbam
    ch_fasta
    ch_fai

    main:
    ch_short_calls_vcf              = Channel.empty()
    ch_short_calls_vcf_tbi          = Channel.empty()
    ch_short_calls_gvcf             = Channel.empty()
    ch_short_calls_gvcf_tbi         = Channel.empty()
    ch_versions                     = Channel.empty()

    /*
     * Call short variants
     */
    if (params.variant_caller == 'medaka') {

        /*
         * Call short variants with medaka
         */
        MEDAKA_VARIANT( ch_view_sortbam, ch_fasta )
        ch_versions = ch_versions.mix(medaka_version = MEDAKA_VARIANT.out.versions)

        /*
         * Zip medaka vcf
         */
        MEDAKA_BGZIP_VCF( MEDAKA_VARIANT.out.vcf )
        ch_short_calls_vcf  = MEDAKA_BGZIP_VCF.out.output
        ch_versions = ch_versions.mix(bgzip_version = MEDAKA_BGZIP_VCF.out.versions)

        /*
         * Index medaka vcf.gz
         */
        MEDAKA_TABIX_VCF( ch_short_calls_vcf )
        ch_short_calls_vcf_tbi  = MEDAKA_TABIX_VCF.out.tbi
        ch_versions = ch_versions.mix(tabix_version = MEDAKA_TABIX_VCF.out.versions)

    } else if (params.variant_caller == 'deepvariant') {

        /*
        * Call variants with deepvariant
        */
        // Create empty channels for optional inputs
        ch_intervals = Channel.value([])
        ch_gzi = Channel.value([])
        ch_par_bed = Channel.value([])

        // Prepare meta channels
        ch_view_sortbam_meta = ch_view_sortbam.map { meta, bam, bai -> [meta, bam, bai, []] }
        ch_fasta_meta = ch_fasta.map { it -> [[:], it] }
        ch_fai_meta = ch_fai.map { it -> [[:], it] }
        ch_gzi_meta = ch_gzi.map { it -> [[:], it] }
        ch_par_bed_meta = ch_par_bed.map { it -> [[:], it] }

        DEEPVARIANT_RUNDEEPVARIANT(
            ch_view_sortbam_meta,
            ch_fasta_meta,
            ch_fai_meta,
            ch_gzi_meta,
            ch_par_bed_meta
        )

        ch_short_calls_vcf = DEEPVARIANT_RUNDEEPVARIANT.out.vcf
        ch_short_calls_vcf_tbi = DEEPVARIANT_RUNDEEPVARIANT.out.vcf_tbi
        ch_short_calls_gvcf = DEEPVARIANT_RUNDEEPVARIANT.out.gvcf
        ch_short_calls_gvcf_tbi = DEEPVARIANT_RUNDEEPVARIANT.out.gvcf_tbi
        ch_versions = ch_versions.mix(DEEPVARIANT_RUNDEEPVARIANT.out.versions)

    } else {

        /*
         * Call variants with pepper_margin_deepvariant (automatic zip + index, docker + singularity only)
         */
        PEPPER_MARGIN_DEEPVARIANT( ch_view_sortbam, ch_fasta, ch_fai )
        ch_short_calls_vcf = PEPPER_MARGIN_DEEPVARIANT.out.vcf
        ch_short_calls_vcf_tbi = PEPPER_MARGIN_DEEPVARIANT.out.tbi
        ch_versions = ch_versions.mix(PEPPER_MARGIN_DEEPVARIANT.out.versions)
    }

    emit:
    ch_short_calls_vcf
    ch_short_calls_vcf_tbi
    ch_short_calls_gvcf
    ch_short_calls_gvcf_tbi
    ch_versions
}
