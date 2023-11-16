#!/bin/bash

PORT=10000

# Inicia o servidor na porta especificada
echo "Aguardando conexões na porta $PORT..."
nc -l -p $PORT | while true; do
    # Lê o nome do arquivo e o conteúdo enviado pelo cliente
    read -r FILENAME
    read -r CONTENT

    echo -e "$CONTENT" > "$FILENAME"

    echo "Arquivo $FILENAME recebido"
done
