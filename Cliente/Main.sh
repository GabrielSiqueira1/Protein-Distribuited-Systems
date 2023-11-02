#!/bin/bash

while true; do

  porta_retorno=$(nc -l -p 9998) # Cada máquina terá sua porta de comunicação com o servidor para que não haja conflitos

  nc -l -p 9998 > "arquivo.txt" # A cada análise, esse loop trava neste ponto, para receber outros arquivos

  arquivo_pdb=arquivo.txt

  max_processos_em_segundo_plano=4 # Número máximo de subprocessos incrementados por &

  # Barrinha indicando que o terminal está ativo
  progresso(){
    local bars="/ - | \\"
    local delay=0.1
    for i in {1..20}; do
      printf "\r[%c]" "${bars:i%8:1}"
      sleep $delay
    done
    printf "\r" 
  }

  # Função para esperar até que o número de processos em segundo plano seja menor que o limite
  esperar_limite_processos() {
    echo "Ocupado com todos os processos ativos" | nc "172.25.41.8" $porta_retorno -q 1
    while [[ $(jobs | wc -l) -ge $max_processos_em_segundo_plano ]]; do
      sleep 1
      progresso
    done
  }

  # Verifique se o arquivo .pdb existe
  if [ ! -f "$arquivo_pdb" ]; then
    echo "O arquivo $arquivo_pdb não existe."
    exit 1
  fi

  # Definição da saída
  menor_distancia="menores_distancias_$arquivo_pdb.txt"

  # Cria o arquivo vazio
  > "$menor_distancia"

  linha_atual=0

  # Loop para processar todas as linhas "ATOM" no arquivo .pdb
  while read -r linha; do
    linha_atual=$((linha_atual + 1))
    if [[ $linha == "ATOM"* ]]; then
      atomo=$(echo "$linha" | awk '{print $2}')
      esperar_limite_processos
      ./CalculaDistancias.sh "$arquivo_pdb" "$atomo" "$menor_distancia" "$linha_atual" 
      echo "Realizando o cálculo do átomo $atomo" | nc "172.25.41.8" $porta_retorno -q 1
    fi
  done < "$arquivo_pdb"

  wait

  echo "Calculando a menor distância geral" | nc "172.25.41.8" $porta_retorno -q 1
  ./VerificarMenor.sh $menor_distancia

  echo "Finalizado" | nc "172.25.41.8" $porta_retorno -q 1

  echo

done
