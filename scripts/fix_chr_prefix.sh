#!/bin/bash

INPUT_BAM="$1"
OUTPUT_BAM="$2"

echo "Checking chromosome format: $INPUT_BAM"

# chr var mı kontrol
if samtools view -H "$INPUT_BAM" | grep -q "SN:chr"; then
    echo "chr prefix already present → copying"
    cp "$INPUT_BAM" "$OUTPUT_BAM"
    cp "$INPUT_BAM.bai" "$OUTPUT_BAM.bai" 2>/dev/null
    exit 0
fi

echo "Adding chr prefix..."

samtools view -h "$INPUT_BAM" | \
awk '
BEGIN {OFS="\t"}
{
    if ($0 ~ /^@SQ/) {
        sub("SN:", "SN:chr", $0)
    }
    else if ($0 !~ /^@/) {
        if ($3 != "*") $3="chr"$3
        if ($7 != "=" && $7 != "*") $7="chr"$7
    }
    print
}' | samtools view -b -o "$OUTPUT_BAM"

samtools index "$OUTPUT_BAM"

echo "Fixed BAM created: $OUTPUT_BAM"
