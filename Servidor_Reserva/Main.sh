#!/bin/bash

PORT=10000

# Inicia o servidor na porta especificada
echo "Aguardando conexões na porta $PORT..."
nc -l -p $PORT | while true; do
    # Lê o nome do arquivo e o conteúdo enviado pelo cliente
    read -r FILENAME
    read -r CONTENT

    # Caminho completo do arquivo de destino
    DEST_FILE="$FILENAME"

    # Salva o conteúdo no arquivo de destino
    echo -e "$CONTENT" > "$DEST_FILE"

    echo "Arquivo recebido e salvo em: $DEST_FILE"
done
