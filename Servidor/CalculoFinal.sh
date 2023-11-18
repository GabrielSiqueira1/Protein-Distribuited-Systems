#!/bin/bash

arquivos=$(ls arquivo_*)

menor_distancia=99999999999999999999

for arquivo in $arquivos; do

    distancia=$(awk '{print $5}' $arquivo)
   
    if (( $(bc <<< "$distancia < $menor_distancia") )); then
        menor_distancia=$distancia
    fi
done

for arquivo in $arquivos; do
    distancia=$(awk '{print $5}' $arquivo)
    if (( $(bc <<< "$distancia == $menor_distancia") )); then
       echo "A menor distância encontrada é $menor_distancia E-10 m, presente no arquivo $arquivo."
    fi
done
