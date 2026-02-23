rule qc_nanoplot:
    input:
        lambda wc: FASTQ_BY_SAMPLE[wc.sample]
    output:
        html="{outdir}/{sample}/qc/nanoplot/NanoPlot-report.html"
    params:
        outdir=lambda wc: f"{OUTDIR}/{wc.sample}/qc/nanoplot"
    threads: 1
    container:
        "docker://quay.io/biocontainers/nanoplot:1.43.0--pyhdfd78af_0"
    shell:
        r"""
        mkdir -p {params.outdir}
        NanoPlot --fastq {input} -o {params.outdir} --threads {threads}
        """