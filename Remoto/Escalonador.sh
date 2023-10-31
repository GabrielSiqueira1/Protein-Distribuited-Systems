#!/bin/bash

arquivo_pdb="$1"
max_processos_em_segundo_plano=9000 # Número máximo de subprocessos incrementados por &

# Função para esperar até que o número de processos em segundo plano seja menor que o limite
esperar_limite_processos() {
  while [[ $(jobs | wc -l) -ge $max_processos_em_segundo_plano ]]; do
    sleep 1
  done
}

# Verifique se o arquivo .pdb existe
if [ ! -f "$arquivo_pdb" ]; then
  echo "O arquivo $arquivo_pdb não existe."
  exit 1
fi

# Definição da saída
menor_distancia="menor_distancia.txt"

# Cria o arquivo vazio
> "$menor_distancia"

# Loop para processar todas as linhas "ATOM" no arquivo .pdb
while read -r linha; do
  if [[ $linha == "ATOM"* ]]; then
    atomo=$(echo "$linha" | awk '{print $2}')
    esperar_limite_processos
    ./CalculaDistancias.sh "$arquivo_pdb" "$atomo" "$menor_distancia" &
  fi
done < "$arquivo_pdb"

wait
