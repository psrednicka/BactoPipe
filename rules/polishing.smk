rule polishing:
    input:
        fq = lambda wc: FASTQ_BY_SAMPLE[wc.sample],
        assembly = f"{OUTDIR}/{{sample}}/assembly/consensus_assembly.fasta"
    output:
        fasta = f"{OUTDIR}/{{sample}}/polishing/medaka/consensus.fasta"
    threads: 16
    container:
        config["containers"]["medaka"]
    params:
        outdir = f"{OUTDIR}/{{sample}}/polishing/medaka",
        model = "r1041_e82_400bps_sup_v5.2.0"
    shell:
        r"""
        set -euo pipefail
        mkdir -p {params.outdir}

        medaka_consensus \
          -i {input.fq} \
          -d {input.assembly} \
          -o {params.outdir} \
          -t {threads} \
          -m {params.model}

        # sanity check: medaka powinna stworzyć consensus.fasta
        test -s {output.fasta}
        """