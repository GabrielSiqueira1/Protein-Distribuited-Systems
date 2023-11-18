#!/bin/bash

arquivo_csv_1="estado_maquina.csv"
arquivo_csv_2="estado_arquivo.csv"

for file in arquivo-*.txt; do
    ip=$(echo $file | awk -F'-' '{print $2}')
    nome_arquivo=$(echo $file | awk -F'-' '{print $3}')
    
    awk -v ip="$ip" -v nome_arquivo="$nome_arquivo" -F',' '$1 == ip && $3 == nome_arquivo { $2 = "NovoEstado"; print }' $arquivo_csv_1 > temp1.csv
    mv temp1.csv $arquivo_csv_1
    
    awk -v nome_arquivo="$nome_arquivo" -F',' '$1 == nome_arquivo { $2 = "NovoEstado"; print }' $arquivo_csv_2 > temp2.csv
    mv temp2.csv $arquivo_csv_2
done

echo "Operação concluída."
