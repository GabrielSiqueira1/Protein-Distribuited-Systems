#!/bin/bash

arquivo_pdb="$1"
declare -a primeiros_atomos=()  # Declarando um array vazio para armazenar os átomos
max_processos_em_segundo_plano=$(ulimit -u)/4  # Defina o número máximo de processos em segundo plano desejado

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

# Loop para processar todas as linhas "ATOM" no arquivo .pdb
while read -r linha; do
  if [[ $linha == "ATOM"* ]]; then
    atomo=$(echo "$linha" | awk '{print $2}')
    primeiros_atomos+=("$atomo")  # Adicione o átomo ao array
  fi
done < "$arquivo_pdb"

# Chame seu script para cada átomo armazenado no vetor
for atomo in "${primeiros_atomos[@]}"; do
  esperar_limite_processos  # Aguarde até que o número de processos em segundo plano seja menor que o limite
  ./seu_script.sh "$arquivo_pdb" "$atomo" &
done

# Aguarde a conclusão de todos os processos em segundo plano
wait
