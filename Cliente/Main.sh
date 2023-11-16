#!/bin/bash

while true; do

  porta_retorno=$(nc -l -p 9998) # Cada máquina terá sua porta de comunicação com o servidor para que não haja conflitos
  echo "$porta_retorno"
  nc -l -p 9998 > "arquivo.txt" # A cada análise, esse loop trava neste ponto, para receber outros arquivos
  ip_server="172.16.111.41"
  ip_server_2="172.16.111.45"

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
  menor_distancia="menores_distancias_$arquivo_pdb"

  # Cria o arquivo vazio
  > "$menor_distancia"

  linha_atual=0

  # Loop para processar todas as linhas "ATOM" no arquivo .pdb
  while read -r linha; do
    linha_atual=$((linha_atual + 1))
    if [[ $linha == "ATOM"* ]]; then
      horario_atual=$(date +"%Y-%m-%d %H:%M:%S")
      atomo=$(echo "$linha" | awk '{print $2}')
      esperar_limite_processos
      frase="      -> Estamos calculando usando atomo $atomo"
      printf "\r%s" "$frase"
      ./CalculaDistancias.sh "$arquivo_pdb" "$atomo" "$menor_distancia" "$linha_atual" & 
      if [ $((linha_atual % 10)) -eq 0 ];then
	      echo "Tempo: $horario_atual -> Realizando o cálculo do átomo $atomo" | nc "$ip_server" $porta_retorno -q 5
      fi
    fi
  done < "$arquivo_pdb"

  wait
  
  echo "Calculando a menor distância geral" | nc "$ip_server" $porta_retorno -q 5
  printf "\r%s" "Calculando a menor distância geral"

  echo 
  
  ./VerificarMenor.sh $menor_distancia
  
  echo "Enviando o arquivo"
  timeout=600
  if [ ! $timeout -eq 0 ]; then
    while true; do
      echo "Finalizado" | nc "$ip_server" $porta_retorno -q 5
      if [ $? -eq 0 ]; then 
        break
      fi
      timeout=$((timeout - 1))
    done
    sleep 5
    while true; do
      nc "$ip_server" $porta_retorno -q 5 < "menor_valor_das_$menor_distancia"
      if [ $? -eq 0 ]; then
          break
      fi 
      timeout=$((timeout - 1))
    done
    # Envio do mesmo arquivo para outro servidor {Replicação}
    menor_valor_das_$menor_distancia >> "arquivo_$(hostname -I)-$porta_retorno.txt"
    nc "$ip_server_2" 10000 -q 5 < "arquivo_$(hostname -I)-$porta_retorno.txt"
  fi
  
  echo "Enviado"

done
