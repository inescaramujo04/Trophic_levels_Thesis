import pandas as pd
import re
from pathlib import Path

# Pasta onde estão os ficheiros Excel
pasta = Path(__file__).parent / "Documentos"
saida = pasta / "ficheiros_FASTQ_charcos"
saida.mkdir(parents=True, exist_ok=True)

# Ler a lista de amostras dos charcos
ponds = pd.read_excel(
    pasta / "Ponds_metagenomic samples.xlsx",
    sheet_name="GENERAL"
)

# Criar uma tabela com o ID, país e ano de cada amostra
info_amostras = ponds[
    ["ID.1", "Country"]
].dropna(subset=["ID.1", "Country"]).copy()

info_amostras["ID.1"] = info_amostras["ID.1"].astype(str).str.strip()

# Remover eventuais duplicados
info_amostras = info_amostras.drop_duplicates(subset=["ID.1"])


# Percorrer os ficheiros Excel das placas
for ficheiro in sorted(pasta.glob("1372_8_Sample_information_P*.xlsx")):

    df = pd.read_excel(
        ficheiro,
        sheet_name="Sample information",
        header=14
    )

    df = df[["NGI Sample ID", "Your sample name"]].dropna().copy()
    df.columns = ["ID_sequenciacao", "Nome_amostra"]

    # Limpar os nomes originais
    df["Nome_amostra"] = df["Nome_amostra"].astype(str).str.strip()

    # Manter apenas as amostras que pertencem aos charcos
    df = df.merge(
        info_amostras,
        left_on="Nome_amostra",
        right_on="ID.1",
        how="inner"
    )

    # Adicionar país e ano ao nome da amostra
    df["Nome_amostra"] = (
        df["Country"].astype(str) + "_" +
        df["Nome_amostra"]
    )

    # Remover espaços e caracteres especiais
    df["Nome_amostra"] = df["Nome_amostra"].apply(
        lambda x: re.sub(r"[^A-Za-z0-9_]", "_", x)
    )

    # Manter apenas as duas colunas necessárias
    df = df[["ID_sequenciacao", "Nome_amostra"]]

    if not df.empty:

        nome_saida = ficheiro.stem.replace(
            "1372_8_Sample_information_", ""
        ) + "_charcos.txt"

        df.to_csv(
            saida / nome_saida,
            sep="\t",
            index=False,
            header=False
        )

        print(f"{nome_saida}: {len(df)} amostras")

print(f"Concluído! Ficheiros guardados em: {saida}")