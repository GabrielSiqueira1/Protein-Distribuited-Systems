#!/bin/bash

# Para a distribuição dos arquivos e a verificação do seu sucesso por parte da máquina central, devemos utilizar os ip's das máquinas em um vetor, bem como um vetor de arquivos. {Naming}
ip_computadores=("192.168.0.57" "192.168.0.58" "192.168.0.59")
pdbs=("teste.ent" "teste2.ent" "teste3.ent")

# Para a coordenação dos processos, criamos dois arquivos .csv cujo o propósito é a identificação do estado de uma máquina e de um arquivo. A máquina poderá estar livre ou ocupada, enquanto o arquivo pode estar como processado ou não. {Coordenação}
arquivo_csv_1="estado_maquina.csv"
arquivo_csv_2="estado_arquivo.csv"

# Inicialização dos arquivos
echo "IP,Estado,Arquivo" > "$arquivo_csv_1"
for ip in "${ip_computadores[@]}"; do
  echo "$ip,Livre" >> "$arquivo_csv_1"
done

echo "Arquivo,Estado,IP" > "$arquivo_csv_2"
for pdb in "${pdbs[@]}"; do
  echo "$pdb,0" >> "$arquivo_csv_2"
done

# Verificação de ip livre no arquivo csv {Coordenação}
ip_livre(){
    local ip="$1"
    local estado=$(grep "$ip" "$arquivo_csv_1" | cut -d',' -f2)
    [[ "$estado" == "Livre" ]]
}

# Distribuição de arquivos entre as máquinas {Coordenação}
for pdb in "${pdbs[@]}"; do
    for ip in "${ip_computadores[@]}"; do
        if ip_livre "$ip"; then
            sed -i "s/$ip,Livre/$ip,Ocupado,$pdb/" "$arquivo_csv_1" # Substituição do valor de estado do ip
            sed -i "s/$pdb,0/$pdb,1/" "$arquivo_csv_2" # Substituição do valor de estado do arquivo para processando

            echo "Enviando o pdb:$pdb para a máquina de ip:$ip"
            # Para que o computador realize sua tarefa este deverá ter uma porta aberta para receber o arquivo da central {Comunicação}
            nc "$ip" 9998 < "$pdb"

            # O processos de monitoramento será em segundo plano  {Processos}
            ( 

                timeout=1200 # Limite de tempo para o processo {Tolerância a falhas}
                resposta=""
                while [ "$timeout" -gt 0 ]; do
                    if [ -z "$resposta" ]; do
                        # É possível utilizar ssh {Segurança}
                        resposta=$(nc -l -p 9998)
                        sleep 1
                        timeout=$((timeout - 1))
                    else
                        break
                    fi
                done

                # Com a conclusão do processo é necessário alterar os arquivos .csv
                if [ ! -z "$reposta" ]; then
                    echo "Arquivo não concluído, devolvendo $pdb ao vetor 'pdbs'"
                    pdbs=("$pdb" "${pdb[@]}") # O arquivo retorna ao vetor de pdbs para que seja novamente processado {Replicação}
                    sed -i "s/$pdb,1/$pdb,0/" "$arquivo_csv_2"
                else 
                    sed -i "s/$ip,Ocupado/$ip,Livre,/" "$arquivo_csv_1"
                    sed -i "s/$pdb,1/$pdb,2/" "$arquivo_csv_2"
                fi
                
             ) &

            break # Interrompe o primeiro loop externo
        fi
    done 
done