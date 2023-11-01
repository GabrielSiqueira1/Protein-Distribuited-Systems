#!/bin/bash

arquivo_pdb="$1"
primeiro_atomo="$2"
menor_distancia="$3"
linha_atual="$4"

tempo_inicial=$(date +%s)

menor=99999.0 # Servirá de comparativo para encontrar a menor distância

# Função para registrar a distância e o tempo de término em um arquivo de log
registrar_log() {
  distancia="$1"
  at1="$2"
  at2="$3"
  tempo_termino="$4"
  echo "Distância entre $at1 e $at2: $distancia E-10 m - Tempo de término: $tempo_termino" >> "$log_file"
}

# Função para calcular a distância entre o primeiro átomo e outro átomo
calcular_distancia() {
  atom2="$1"
  coordenadas_atom2=($(grep "^ATOM *$atom2 *" "$arquivo_pdb" | awk '{print $7, $8, $9}'))

  if [ $atom2 -gt $primeiro_atomo ]; then
    distancia=`echo "scale=3;sqrt((${coordenadas_primeiro_atomo[0]} - ${coordenadas_atom2[0]})^2 + (${coordenadas_primeiro_atomo[1]} - ${coordenadas_atom2[1]})^2 + (${coordenadas_primeiro_atomo[2]} - ${coordenadas_atom2[2]})^2)" | bc`

    if (( $(bc <<< "$distancia < $menor") )); then
      menor="$distancia"
      echo "$menor" > menor_distancia_$primeiro_atomo.tmp
    fi
  fi
}

# Extrai as coordenadas do primeiro átomo
coordenadas_primeiro_atomo=($(grep "^ATOM.*$primeiro_atomo" "$arquivo_pdb" | awk '{print $7, $8, $9}'))

linha_atual=1
total_linhas=$(wc -l < "$arquivo_pdb")

# Loop para calcular a distância do primeiro átomo com todos os outros átomos no arquivo PDB
tail -n +$linha_atual "$arquivo_pdb" | grep "^ATOM" | awk '{print $2}' | while read -r atom2; do
  calcular_distancia "$atom2" 
done

tempo_final=$(date +%s)

tempo_total=$((tempo_final - tempo_inicial))

menor=$(cat menor_distancia_$primeiro_atomo.tmp)

echo "Menor distância encontrada para o átomo $primeiro_atomo é de: $menor E-10 m, em um tempo de: $tempo_total" >> "$menor_distancia"

rm menor_distancia_$primeiro_atomo.tmp