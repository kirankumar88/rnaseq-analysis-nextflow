import sys
import pandas as pd
from pydeseq2.dds import DeseqDataSet
from pydeseq2.ds import DeseqStats

# -------------------------------
# Input handling
# -------------------------------
if len(sys.argv) < 2:
    raise ValueError("Usage: python pydeseq2_analysis.py <counts.txt> [metadata.csv]")

counts_file = sys.argv[1]
metadata_file = sys.argv[2] if len(sys.argv) > 2 else None

# -------------------------------
# Load counts
# -------------------------------
df = pd.read_csv(counts_file, sep="\t", comment="#", index_col=0)

# Remove featureCounts annotation columns
df = df.iloc[:, 5:]
df = df.astype(int)

print(f"[INFO] Loaded count matrix (genes x samples): {df.shape}")

# 🔥 CRITICAL FIX: transpose
df = df.T

print(f"[INFO] Transposed matrix (samples x genes): {df.shape}")

# -------------------------------
# Metadata handling
# -------------------------------
if metadata_file:
    print(f"[INFO] Using metadata file: {metadata_file}")
    metadata = pd.read_csv(metadata_file, index_col=0)

    # Ensure same order as counts
    metadata = metadata.loc[df.index]

else:
    print("[WARNING] No metadata provided — using automatic grouping")

    n = df.shape[0]

    if n < 2:
        raise ValueError("DESeq2 requires at least 2 samples")

    half = n // 2
    conditions = ["A"] * half + ["B"] * (n - half)

    metadata = pd.DataFrame({
        "condition": conditions
    }, index=df.index)

print("[INFO] Final sample order:", df.index.tolist())
print("[INFO] Metadata:")
print(metadata)

# -------------------------------
# DESeq2 analysis
# -------------------------------
dds = DeseqDataSet(
    counts=df,
    metadata=metadata,
    design_factors="condition"
)

dds.deseq2()

stats = DeseqStats(dds, contrast=("condition", "treated", "control"))
stats.summary()

res = stats.results_df

# -------------------------------
# Save outputs
# -------------------------------
res.to_csv("deseq2_results.csv")

# Ranking for downstream use
if "stat" in res.columns:
    res["stat"].sort_values(ascending=False).to_csv(
        "gene_rank.rnk",
        sep="\t",
        header=False
    )
else:
    print("[WARNING] 'stat' column missing — skipping ranking file")

print("[INFO] DESeq2 analysis completed successfully")
