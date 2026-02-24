MIN_LEN = int(config.get("min_len", 1000))
MIN_Q   = int(config.get("min_q", 10))

rule nanofilt:
    input:
        lambda wc: FASTQ_BY_SAMPLE[wc.sample]
    output:
        f"{OUTDIR}/{{sample}}/filtered/{{sample}}.filtered.fastq.gz"
    threads: 1
    container:
        config["containers"]["nanofilt"]

    shell:
        r"""
    set -euo pipefail

    mkdir -p $(dirname {output})

    if ! zcat {input} | NanoFilt -q {MIN_Q} -l {MIN_LEN} | gzip > {output}; then
        echo "TECH FAIL: {wildcards.sample} — NanoFilt crashed" >&2
        touch {OUTDIR}/{wildcards.sample}/filtered/FAILED
        exit 1
    fi

    if [ ! -s {output} ]; then
        echo "FILTER FAIL: {wildcards.sample} — no reads passed filtering" >&2
        touch {OUTDIR}/{wildcards.sample}/filtered/FAILED
        rm -f {output}
        exit 1
    fi

    echo "NanoFilt OK: {wildcards.sample}"
    """