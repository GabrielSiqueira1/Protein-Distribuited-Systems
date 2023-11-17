#!/bin/bash

PORT=10000

# Inicia o servidor na porta especificada
echo "Aguardando conexões na porta $PORT..."

while true; do

    filename=$(nc -l -p $PORT)
    nc -l -p $PORT > "arquivo.txt"

    mv arquivo.txt $filename

    echo "Arquivo recebido"
done
