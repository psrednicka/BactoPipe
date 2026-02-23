import os
from glob import glob
from pathlib import Path

INPUT_DIR = config["input"]
OUTDIR = config["output"]

# znajdź wszystkie fastq(.gz) w katalogu input
FASTQS = sorted(
    glob(os.path.join(INPUT_DIR, "*.fastq.gz")) +
    glob(os.path.join(INPUT_DIR, "*.fq.gz")) +
    glob(os.path.join(INPUT_DIR, "*.fastq")) +
    glob(os.path.join(INPUT_DIR, "*.fq"))
)

if not FASTQS:
    raise ValueError(f"Nie znaleziono FASTQ w {INPUT_DIR}")

# funkcja do wyodrębniania nazwy próbki ze ścieżki pliku
def sample_from_path(p):
    name = Path(p).name
    for ext in [".fastq.gz", ".fq.gz", ".fastq", ".fq"]:
        if name.endswith(ext):
            return name.replace(ext, "")
    raise ValueError(f"Nieznane rozszerzenie: {name}")

# lista próbek
SAMPLES = [sample_from_path(p) for p in FASTQS]

# mapowanie sample -> ścieżka
FASTQ_BY_SAMPLE = {sample_from_path(p): p for p in FASTQS}

include: "rules/qc_nanoplot.smk"
include: "rules/qc_nanofilt.smk"
include: "rules/qc_nanofilt_filtered.smk"
include: "rules/assembly.smk"
include: "rules/polishing.smk"

rule all:
    input:
         # raport NanoPlot (przed filtracją)
        expand("{outdir}/{sample}/qc/nanoplot/NanoPlot-report.html",
               outdir=OUTDIR, sample=SAMPLES),
        # wynik NanoFilt
        expand("{outdir}/{sample}/filtered/{sample}.filtered.fastq.gz",
               outdir=OUTDIR, sample=SAMPLES),
        # raport NanoPlot (po filtracji)
        expand("{outdir}/{sample}/qc/nanoplot_filtered/NanoPlot-report.html",
               outdir=OUTDIR, sample=SAMPLES),
        # wynik złożenia genomu
        expand("{outdir}/{sample}/assembly/consensus_assembly.fasta",
                outdir=OUTDIR, sample=SAMPLES),
        # wynik polerowania
        expand("{outdir}/{sample}/polishing/medaka/consensus.fasta",
                outdir=OUTDIR, sample=SAMPLES)
        
                