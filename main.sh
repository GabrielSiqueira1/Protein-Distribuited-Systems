#!/bin/bash

# Configurações do Samba 
username=""
password=""
caminho_pasta_compartilhada="//MEU-IP/Protein"
mkdir ./Testes/
caminho_no_computador="./Testes"

# Montagem
sudo mount.cifs "$caminho_pasta_compartilhada" "$caminho_no_computador" -o username="$username",password="$password"

cd ./Testes/1

arquivos_ent=(*.ent)

if [ ${#arquivo_ent[@]} -gt 0 ]; then
    indice_aleatorio=$((RANDOM % ${#arquivo_ent[@]}))
    arquivo="${arquivos_ent[$indice_aleatorio]}"
fi

cd ../

./CalculaDistancias.sh "./1/$arquivo

mv log_$arquivo.txt ./1/
mv ./1/$arquivo ./2/

./VerificarMenor.sh "./1/log_$arquivo.txt"

mv menor_log_$arquivo.txt ./1/