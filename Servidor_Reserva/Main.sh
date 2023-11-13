#!/bin/bash

diretorio_origem="./"
maquina_destino="172.16.111.41"
porta_destino="11000"
porta_recebimento="10000"

verificar_arquivos() {
    ls "$diretorio_origem"/*.txt 2>/dev/null
}

while true; do
    # Verifica se há arquivos no diretório
    if arquivos=$(verificar_arquivos); then
        # Envia todos os arquivos para a máquina de destino usando o netcat
        for arquivo in $arquivos; do
	    nome_arquivo=$(basename "$arquivo")
            nc -q 1 "$maquina_destino" "$porta_destino" < "$arquivo"
            echo "Enviado: $arquivo"
        done
    fi

    # Verifica se há arquivos recebidos na porta de recebimento
    arquivo_recebido=$(nc -l -p "$porta_recebimento" -q 1)

    if [ -n "$arquivo_recebido" ]; then
        nome_arquivo=$(basename "$arquivo_recebido")
        mv "$arquivo_recebido" "$diretorio_origem/$nome_arquivo"
        echo "Recebido: $nome_arquivo"
    fi

    sleep 1
done
