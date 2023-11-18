#!/bin/bash

arquivos=$(ls *.txt)

menor_distancia=99999999999999999999

for arquivo in $arquivos; do

    distancia=$(awk '{if ($5 < menor) menor=$5} END {print menor}' $arquivo)
    
    if (( $(echo "$distancia < $menor_distancia" | bc -l) )); then
        menor_distancia=$distancia
    fi
done

for arquivo in $arquivos; do
    awk -v menor_distancia="$menor_distancia" '$5 == menor_distancia {print $3, $4}' $arquivo
done
