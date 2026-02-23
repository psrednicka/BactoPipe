rule nanoplot_filtered:
    input:
        f"{OUTDIR}/{{sample}}/filtered/{{sample}}.filtered.fastq.gz"
    output:
        f"{OUTDIR}/{{sample}}/qc/nanoplot_filtered/NanoPlot-report.html"
    threads: 4
    container:
        "docker://quay.io/biocontainers/nanoplot:1.43.0--pyhdfd78af_0"
    shell:
        r"""
        set -euo pipefail
        outdir=$(dirname {output})
        mkdir -p "$outdir"
        NanoPlot --fastq {input} -o "$outdir" --threads {threads}
        """