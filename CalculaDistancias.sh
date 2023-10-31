#!/bin/bash

arquivo_pdb="$1"

# Extrai o primeiro átomo do arquivo PDB
primeiro_atomo=$(grep "^ATOM" "$arquivo_pdb" | head -n 1 | awk '{print $2}')

# Saída
log_file="log_$arquivo_pdb.txt"

# Cria o arquivo vazio
> "$log_file"

# Função para registrar a distância e o tempo de término em um arquivo de log
registrar_log() {
  distancia="$1"
  at1="$2"
  at2="$3"
  tempo_termino="$4"
  echo "Distância entre $at1 e $at2: $distancia e-10 m - Tempo de término: $tempo_termino" >> "$log_file"
}

# Função para calcular a distância entre o primeiro átomo e outro átomo
calcular_distancia() {
  atom2="$1"
  coordenadas_atom2=($(grep "^ATOM *$atom2 *" "$arquivo_pdb" | awk '{print $7, $8, $9}'))

  if [ $atom2 -gt $primeiro_atomo ]; then
    distancia=`echo "scale=3;sqrt((${coordenadas_primeiro_atomo[0]} - ${coordenadas_atom2[0]})^2 + (${coordenadas_primeiro_atomo[1]} - ${coordenadas_atom2[1]})^2 + (${coordenadas_primeiro_atomo[2]} - ${coordenadas_atom2[2]})^2)" | bc`

    registrar_log "$distancia" "$primeiro_atomo" "$atom2" "$(date +'%Y-%m-%d %H:%M:%S')"
  fi
}

# Extrai as coordenadas do primeiro átomo
coordenadas_primeiro_atomo=($(grep "^ATOM.*$primeiro_atomo" "$arquivo_pdb" | awk '{print $7, $8, $9}'))

# Loop para calcular a distância do primeiro átomo com todos os outros átomos no arquivo PDB
grep "^ATOM" "$arquivo_pdb" | awk '{print $2}' | while read -r atom2; do
  calcular_distancia "$atom2" & 
done

# Espera pela conclusão de ambos os processos em segundo plano
wait