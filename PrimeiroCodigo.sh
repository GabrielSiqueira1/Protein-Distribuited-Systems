#!/bin/bash

# Verifica se o número correto de argumentos foi fornecido
#if [ "$#" -ne 2 ]; then
#  #echo "Uso: $0 arquivo.pdb destino_remoto:porta"
#  echo "Uso: $0 arquivo.ent"
#  exit 1
#fi

# Nome do arquivo PDB
arquivo_pdb="$1"

# Nome do destino remoto e porta (formato: host:porta)
#destino_remoto="$2"

# Nome do arquivo de log
log_file="log.txt"

# Função para registrar a distância e o tempo de término em um arquivo de log
registrar_log() {
  distancia="$1"
  tempo_termino="$2"
  echo "Distância: $distancia Ångströms - Tempo de término: $tempo_termino" >> "$log_file"
}

# Extrai o primeiro átomo do arquivo PDB
primeiro_atomo=$(grep "^ATOM" "$arquivo_pdb" | head -n 1 | awk '{print $3}')

# Extrai as coordenadas do primeiro átomo
coordenadas_primeiro_atomo=($(grep "^ATOM.*$primeiro_atomo" "$arquivo_pdb" | awk '{print $7, $8, $9}'))

# Verifica se o primeiro átomo foi encontrado no arquivo PDB
if [ ${#coordenadas_primeiro_atomo[@]} -eq 0 ]; then
  echo "Átomo $primeiro_atomo não encontrado no arquivo PDB."
  exit 1
fi

# Remove a linha do primeiro átomo do arquivo PDB em segundo plano
#sed -i "/^ATOM.*$primeiro_atomo/d" "$arquivo_pdb" &

# Função para calcular a distância entre o primeiro átomo e outro átomo
calcular_distancia() {
  atom2="$1"
  coordenadas_atom2=($(grep "^ATOM.*$atom2" "$arquivo_pdb" | awk '{print $7, $8, $9}'))
  
  # Verifica se o átomo foi encontrado no arquivo PDB
  if [ ${#coordenadas_atom2[@]} -eq 0 ]; then
    echo "Átomo $atom2 não encontrado no arquivo PDB."
  else
    distancia=`echo "scale=3;sqrt((${coordenadas_primeiro_atomo[0]} - ${coordenadas_atom2[0]})^2 + (${coordenadas_primeiro_atomo[1]} - ${coordenadas_atom2[1]})^2 + (${coordenadas_primeiro_atomo[2]} - ${coordenadas_atom2[2]})^2)" | bc`
    registrar_log "$distancia" "$(date +'%Y-%m-%d %H:%M:%S')"
    echo "Distância entre $primeiro_atomo e $atom2: $distancia Ångströms"
  fi
}

# Cria um arquivo de log vazio
> "$log_file"

# Loop para calcular a distância do primeiro átomo com todos os outros átomos no arquivo PDB
grep "^ATOM" "$arquivo_pdb" | awk '{print $3}' | while read -r atom2; do
  calcular_distancia "$atom2" &
done

# Espera pela conclusão de ambos os processos em segundo plano
wait

# Usa nc para transferir o arquivo modificado para o destino remoto
#nc -w 5 -q 1 "$destino_remoto" < "$arquivo_pdb"

# Verifica se a transferência foi bem-sucedida
#if [ $? -eq 0 ]; then
#  echo "Arquivo enviado com sucesso para $destino_remoto"
#else
#  echo "Falha ao enviar o arquivo para $destino_remoto"
#fi
