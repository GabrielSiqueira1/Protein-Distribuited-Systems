#!/bin/bash

# Nome dos arquivos CSV
arquivo_csv="estado_maquina.csv"
arquivo_csv_2="estado_arquivo.csv"

for file in arquivo-*.txt; do
    ip=$(echo "$file" | cut -d'-' -f2 | cut -d'.' -f1-4)

    if grep -q "$ip" "$arquivo_csv"; then
        linha=$(grep "$ip" "$arquivo_csv")

        filename=$(echo "$linha" | cut -d',' -f3)

        if grep -q "$filename" "$arquivo_csv_2"; then
            sed -i "s/$filename,1,/$filename,2,/" "$arquivo_csv_2"
        fi
    fi
done

echo "Operação concluída."
