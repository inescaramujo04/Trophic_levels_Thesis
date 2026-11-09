import pandas as pd
import re
from pathlib import Path

# Folder containing the Excel files
folder = Path(__file__).parent / "Documents"
output_folder = folder / "FASTQ_pond_files"
output_folder.mkdir(parents=True, exist_ok=True)

# Read the list of pond samples
ponds = pd.read_excel(
    folder / "Ponds_metagenomic samples.xlsx",
    sheet_name="GENERAL"
)

# Create a table with the ID and country of each sample
sample_info = ponds[
    ["ID.1", "Country"]
].dropna(subset=["ID.1", "Country"]).copy()

sample_info["ID.1"] = sample_info["ID.1"].astype(str).str.strip()

# Remove potential duplicates
sample_info = sample_info.drop_duplicates(subset=["ID.1"])


# Iterate through the plate Excel files
for file in sorted(folder.glob("1372_8_Sample_information_P*.xlsx")):

    df = pd.read_excel(
        file,
        sheet_name="Sample information",
        header=14
    )

    df = df[["NGI Sample ID", "Your sample name"]].dropna().copy()
    df.columns = ["Sequencing_ID", "Sample_name"]

    # Clean the original sample names
    df["Sample_name"] = df["Sample_name"].astype(str).str.strip()

    # Keep only samples belonging to the ponds
    df = df.merge(
        sample_info,
        left_on="Sample_name",
        right_on="ID.1",
        how="inner"
    )

    # Add the country to the sample name
    df["Sample_name"] = (
        df["Country"].astype(str) + "_" +
        df["Sample_name"]
    )

    # Remove spaces and special characters
    df["Sample_name"] = df["Sample_name"].apply(
        lambda x: re.sub(r"[^A-Za-z0-9_]", "_", x)
    )

    # Keep only the two required columns
    df = df[["Sequencing_ID", "Sample_name"]]

    if not df.empty:

        output_name = file.stem.replace(
            "1372_8_Sample_information_", ""
        ) + "_ponds.txt"

        df.to_csv(
            output_folder / output_name,
            sep="\t",
            index=False,
            header=False
        )

        print(f"{output_name}: {len(df)} samples")

print(f"Completed! Files saved in: {output_folder}")