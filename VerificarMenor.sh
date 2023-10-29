#!/bin/bash

log_pdb="$1"

menor_distancia=""
atomos_comparados=""

menor_valor="menor_$log_pdb"

> "$menor_valor"

while IFS= read -r linha; do
    # De acordo com o arquivo produzido por CalculaDistancias.sh, a distâncias entre os átomos fica na sexta posição e os átomos comparados, na terceira e na quinta
    distancia=$(echo "$linha" | awk '{print $6}')
    atomos=$(echo "$linha" | awk '{print $3, $5}')
    tempo_termino=$(echo "$linha" | awk '{print $14}')

    if [ -z "$menor_distancia" ] || (( $(echo "$distancia < $menor_distancia" | bc -l) )); then
        menor_distancia="$distancia"
        atomos_comparados="$atomos"
        tempo_termino="$tempo_termino"
    fi
done < "$log_pdb"

echo "Distância entre $atomos_comparados $menor_distancia e-10 m - Tempo de término: $tempo_termino" >> "$menor_valor"
