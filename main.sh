#!/bin/bash

# Configurações do Samba 
username=""
password=""
caminho_pasta_compartilhada="//MEU-IP/Protein"
mkdir ./Testes/
caminho_no_computador="./Testes"

# Montagem
sudo mount.cifs "$caminho_pasta_compartilhada" "$caminho_no_computador" -o username="$username",password="$password"

cd ./Testes/pdbs
arquivos_ent=(*.ent)

# Irá operar por tempo indeterminado
while [ ${#arquivo_ent[@]} -gt 0 ]; do
    indice_aleatorio=$((RANDOM % ${#arquivo_ent[@]}))
    arquivo="${arquivos_ent[$indice_aleatorio]}"

    cd ../

    ## Será que seria melhor mover o arquivo para um diretório pessoal 
    ## E realizar paralelamente com & ?

    ./CalculaDistancias.sh "./pdbs/$arquivo" 

    mv log_$arquivo.txt ./logs/

    ./VerificarMenor.sh "./logs/log_$arquivo.txt"

    mv menor_log_$arquivo.txt ./menor/ 

    cd ./Testes/pdbs
    arquivos_ent=(*.ent)
done

