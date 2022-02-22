workflow generate_master_annotation_table {
    Int preemptible_tries

    call merge_eggnog_outputs {
        input:
        num_preemptible=preemptible_tries
    }

    call genes_to_mags_mapping {
        input:
        eggnog_annotations=merge_eggnog_outputs.eggnog_table,
        num_preemptible=preemptible_tries
    }
}

task merge_eggnog_outputs {
    Array[File] eggnog_output_files
    Int num_preemptible

    command {

        head -n 1 eggnog_output_files[1] > merged_eggnog_output.tsv
        cat ${write_lines(eggnog_output_files)} > eggnog_output.txt
        while read eggnog_file; do
            tail -n+2 $eggnog_file >> merged_eggnog_output.tsv
        done <eggnog_output.txt
    }

    output {
        File eggnog_table = "merged_eggnog_output.tsv"
    }

    runtime {
        docker: "gcr.io/osullivan-lab/gene-mapper:080321"
        cpu: 2
        memory: "4GB"
        preemptible: num_preemptible
        maxRetries: num_preemptible + 1
        bootDiskSizeGb: 50
        zones: "us-central1-a us-central1-b us-central1-c us-central1-f"
        disks: "local-disk 200 HDD"
    }
}

task genes_to_mags_mapping {
    Array[File] contigs
    File gene_catalogue
    File gene_clusters
    File eggnog_annotations
    Array[File] metabat2_bins
    Array[File] gtdbtk_output
    Array[File] checkm_output
    Int num_preemptible
    Int gene_mapper_memory_gb
    Int gene_mapper_disk_gb

    command {

        # concatenate contigs together to merged_min500.contigs.fa
        cat ${write_lines(contigs)} > contig_fasta.txt
        while read fasta_file; do
            cat $fasta_file >> merged_min500.contigs.fa
        done <contig_fasta.txt

        # extract MAGs to directory 'bins'
        mkdir bins
        cat ${write_lines(metabat2_bins)} > metabat2_bins.txt
        while read bin_file; do
            tar -xf $bin_file -C bins/
        done <metabat2_bins.txt

        # copy GTDBTk output summaries to directory gtdbtk
        mkdir gtdbtk
        cat ${write_lines(gtdbtk_output)} > gtdbtk_2_download.txt
        while read gtdbtk_file; do
            cp $gtdbtk_file gtdbtk/
        done <gtdbtk_2_download.txt

        # copy CheckM output summaries to directory checkm
        mkdir checkm
        cat ${write_lines(checkm_output)} > checkm_2_download.txt
        while read checkm_file; do
            cp $checkm_file checkm/
        done <checkm_2_download.txt

        python3 /app/genes_MAGS_eggNOG_mapping.py \
            --genes_file ${gene_catalogue} \
            --cluster_file ${gene_clusters} \
            --contigs_file merged_min500.contigs.fa \
            --eggnog_ann_file ${eggnog_annotations} \
            --bin_fp bins \
            --tax_fp gtdbtk \
            --checkm_fp checkm \
            --out_folder .

    }
    
    output {
        File gene_cluster_info = "Mapped_genes_cluster.tsv"
        File gene_info = "Individual_mapped_genes.tsv"
        File MAG_info = "MAGS.tsv"
    }
    
    runtime {
        docker: "gcr.io/osullivan-lab/gene-mapper:080321"
        cpu: 2
        memory: gene_mapper_memory_gb + "GB"
        preemptible: num_preemptible
        maxRetries: num_preemptible + 1
        bootDiskSizeGb: 50
        zones: "us-central1-a us-central1-b us-central1-c us-central1-f"
        disks: "local-disk " + gene_mapper_disk_gb + " HDD"
    }
}