#!/bin/bash

set -e

echo "=== Contamination QC Pipeline ==="

read -p "BAM klasör yolunu gir: " INPUT_DIR

OUT="qc_results"
THREADS=8

REF=~/verifybam_resources/reference/hg38.nochr.fa
SVD=~/verifybam_resources/panel/1000g.phase3.10k.b38.exome.vcf.gz.dat

rm -rf "$OUT" clean_bam
mkdir -p "$OUT/verifybamid"
mkdir -p "$OUT/ngstf"
mkdir -p clean_bam

echo "Input klasör: $INPUT_DIR"

echo "=== Running VerifyBamID2 ==="

find "$INPUT_DIR" -name "*.bam" ! -name "*_chr.bam" -print0 | while IFS= read -r -d '' bam
do
    name=$(basename "$bam" .bam)

    echo "→ $name"

    verifybamid2 \
    --Reference "$REF" \
    --BamFile "$bam" \
    --SVDPrefix "$SVD" \
    --NumThread 4 \
    --Output "$OUT/verifybamid/$name" || echo "VerifyBamID2 FAILED: $name"
done

echo "=== Preparing clean BAMs for NGSTF ==="

find "$INPUT_DIR" -name "*_chr.bam" -print0 | while IFS= read -r -d '' bam
do
    name=$(basename "$bam")

    cp "$bam" "clean_bam/$name"

    if [ -f "$bam.bai" ]; then
        cp "$bam.bai" "clean_bam/$name.bai"
    else
        samtools index "clean_bam/$name"
    fi
done

echo "=== Generating NGSTF metadata ==="

echo -e "Sample_Name\tBam_Path\tSequencing\tSex" > "$OUT/metadata.tsv"

find clean_bam -name "*.bam" | while read bam
do
    name=$(basename "$bam" .bam)
    echo -e "$name\t$(pwd)/$bam\tDNA\tMale" >> "$OUT/metadata.tsv"
done

echo "=== Running NGSTF ==="

ngsTroubleFinder -m "$OUT/metadata.tsv" -o "$OUT/ngstf" -p "$THREADS"

echo "=== Generating Summary ==="

python3 - <<EOF
import pandas as pd
import glob

# thresholds
NGSTF_TH = 0.05
VB_TH = 0.02

# VerifyBamID2
vb = {}
for f in glob.glob("qc_results/verifybamid/*.selfSM"):
    name = f.split("/")[-1].replace(".selfSM","")
    df = pd.read_csv(f, sep="\t")
    vb[name] = float(df.iloc[0,6])

# NGSTF
ng = pd.read_csv("qc_results/ngstf/qcReport.tsv", sep="\t")

rows = []
for _, row in ng.iterrows():
    sample = row["name"]
    sample_clean = sample.replace("_chr","")
    ng_val = float(row["contamination"])
    vb_val = vb.get(sample_clean, 0)

    if ng_val < NGSTF_TH:
        sex = row["originalSex"]
    else:
        sex = row["genomicSex"]

    rows.append({
        "Sample": sample_clean,
        "VerifyBamID2": vb_val,
        "NGSTF": ng_val,
        "Sex": sex
    })

out = pd.DataFrame(rows)

# Excel + highlight
with pd.ExcelWriter("qc_results/contamination_summary.xlsx", engine="openpyxl") as writer:
    out.to_excel(writer, index=False, sheet_name="QC")

    ws = writer.sheets["QC"]

    from openpyxl.styles import PatternFill
    yellow = PatternFill(start_color="FFFF00", end_color="FFFF00", fill_type="solid")

    for i, row in out.iterrows():
        if row["NGSTF"] >= NGSTF_TH or row["VerifyBamID2"] >= VB_TH:
            for col in range(1, 5):
                ws.cell(row=i+2, column=col).fill = yellow

print("Summary + highlight DONE")
EOF

echo "=== QC DONE ==="

echo "=== Cleaning temporary files ==="
rm -rf clean_bam
rm -f qc_results/metadata.tsv

echo "=== CLEANUP DONE ==="
