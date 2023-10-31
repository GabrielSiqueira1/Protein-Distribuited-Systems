#!/bin/bash

log_pdb="$1"
menor_distancia="$2"

menor_valor=""
atomos_comparados=""

while IFS= read -r linha; do
    # De acordo com o arquivo produzido por CalculaDistancias.sh, a distâncias entre os átomos fica na sexta posição e os átomos comparados, na terceira e na quinta
    distancia=$(echo "$linha" | awk '{print $6}')
    atomos=$(echo "$linha" | awk '{print $3, $5}')
    tempo_termino=$(echo "$linha" | awk '{print $14}')

    if [ -z "$menor_valor" ] || (( $(echo "$distancia < $menor_valor" | bc -l) )); then
        menor_valor="$distancia"
        atomos_comparados="$atomos"
        tempo_termino="$tempo_termino"
    fi
done < "$log_pdb"

echo "Distância entre $atomos_comparados $menor_valor E-10 m - Tempo de término: $tempo_termino" >> "$menor_distancia"
