rule assembly:
    input:
        reads = f"{OUTDIR}/{{sample}}/filtered/{{sample}}.filtered.fastq.gz"
    output:
        f"{OUTDIR}/{{sample}}/assembly/consensus_assembly.fasta"
    threads: 16
    container:
        config["containers"]["autocycler"]
    shell:
        r"""
        set -euo pipefail

        reads="{input.reads}"
        threads="{threads}"

        workdir="{OUTDIR}/{wildcards.sample}/assembly/autocycler_work"
        outdir="$workdir/autocycler_out"

        mkdir -p "$workdir"
        cd "$workdir"

        genome_size=$(autocycler helper genome_size --reads "$reads" --threads "$threads")

        autocycler subsample --reads "$reads" --out_dir subsampled_reads --genome_size "$genome_size"

        mkdir -p assemblies
        for assembler in canu flye metamdbg miniasm necat nextdenovo plassembler raven; do
            for i in 01 02 03 04; do
                autocycler helper "$assembler" \
                    --reads "subsampled_reads/sample_${{i}}.fastq" \
                    --out_prefix "assemblies/${{assembler}}_${{i}}" \
                    --threads "$threads" \
                    --genome_size "$genome_size"
            done
        done

        rm -f subsampled_reads/*.fastq || true

        autocycler compress -i assemblies -a "$outdir"
        autocycler cluster  -a "$outdir"

        shopt -s nullglob
        clusters=( "$outdir"/clustering/qc_pass/cluster_* )
        if [ ${{#clusters[@]}} -eq 0 ]; then
            echo "ERROR: No QC-pass clusters found in $outdir/clustering/qc_pass" >&2
            exit 1
        fi

        for c in "${{clusters[@]}}"; do
            autocycler trim -c "$c"
            autocycler resolve -c "$c"
        done

        autocycler combine -a "$outdir" -i "$outdir"/clustering/qc_pass/cluster_*/5_final.gfa

        mkdir -p "{OUTDIR}/{wildcards.sample}/assembly"
        cp -f "$outdir/consensus_assembly.fasta" "{output}"
        """
