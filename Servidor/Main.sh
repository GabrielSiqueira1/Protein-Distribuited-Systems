#!/bin/bash

# Para a distribuição dos arquivos e a verificação do seu sucesso por parte da máquina central, devemos utilizar os ip's das máquinas em um vetor, bem como um vetor de arquivos. {Naming}
ip_computadores=("192.168.0.116")
pdbs=("pdb1h6n.ent")

# Para a coordenação dos processos, criamos dois arquivos .csv cujo o propósito é a identificação do estado de uma máquina e de um arquivo. A máquina poderá estar livre ou ocupada, enquanto o arquivo pode estar como processado ou não. {Coordenação}
arquivo_csv_1="estado_maquina.csv"
arquivo_csv_2="estado_arquivo.csv"

# Inicialização dos arquivos
echo "IP,Estado,Arquivo,Comunicação" > "$arquivo_csv_1"
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

arquivos_concluidos() {
  count=$(sed -n 's/.*,2,.*//p' $arquivo_csv_2 | wc -l)

  [[ "$count" -eq "${#pdbs[@]}" ]]
}

indice_arquivo=0

# Distribuição de arquivos entre as máquinas {Coordenação}
while ! arquivos_concluidos; do
	#if ! arquivos_concluidos; then # É possível que o código fique preso neste momento pois o if do ip_livre já não realiza o break no final do procedimento
		for ip in "${ip_computadores[@]}"; do
			if ip_livre "$ip"; then

				pdb=""
				for ((i = 0; i < ${#pdbs[@]}; i++)); do
					if [[ $(grep "${pdbs[i]},0" "$arquivo_csv_2") ]]; then
						pdb="${pdbs[i]}"
						indice_arquivo=$i
					break
					fi
				done

				if [ ! -z "$pdb" ]; then
					pdb="${pdbs[$indice_arquivo]}"
					echo "Enviando o pdb:$pdb para a máquina de ip:$ip"
					indice_arquivo=$((indice_arquivo + 1))
					# Para que o computador realize sua tarefa este deverá ter uma porta aberta para receber o arquivo da central {Comunicação}

				sleep 1
					echo "$indice_arquivo" | nc -q 10 "$ip" 9998 # Envio da porta de retorno
					if [ $? -eq 0 ]; then
						sleep 1
						nc "$ip" 9998 -q 10 < "$pdb" # Interrupção do socket e envio do pdb {Segurança}
						echo "Enviado"
					
						sed -i "s/$ip,Livre/$ip,Ocupado,$pdb/" "$arquivo_csv_1" # Substituição do valor de estado do ip
						sed -i "s/$pdb,0/$pdb,1,$ip/" "$arquivo_csv_2" # Substituição do valor de estado do arquivo para processando
						
						# O processos de monitoramento será em segundo plano  {Processos}
					( 

						timeout=200 # Limite de tempo para o processo {Tolerância a falhas}
						resposta=""
						
						while [ "$timeout" -gt 0 ]; do
						echo "$timeout" > "timeout_$pdb.txt"
							resposta=$(timeout 1 nc -l -p $indice_arquivo)
							if [ -z "$resposta" ]; then
								sleep 1
								timeout=$((timeout - 1))
							elif [ ! "$resposta" = "Finalizado" ]; then
								timeout=200 # Reset de tempo
						sleep 1
								sed -i "s/$ip,Ocupado,$pdb.*/$ip,Ocupado,$pdb,$resposta/" "$arquivo_csv_1"
							else
								sed -i "s/$ip,Ocupado,$pdb.*/$ip,Ocupado,$pdb,$resposta/" "$arquivo_csv_1"
								while true; do
									nc -l -p $indice_arquivo > "arquivo_$ip-$pdb.txt"
									if [ $? -eq 0 ]; then
									sleep 1
									break
								fi
						done
								break
							fi
						done

					sleep 1
						# Com a conclusão do processo é necessário alterar os arquivos .csv
						if [ "$timeout" -eq 0 ]; then
							echo "Arquivo não concluído"
							while true; do
								sed -i "s/$pdb,1/$pdb,0/" "$arquivo_csv_2"
								if [ $? -eq 0 ]; then
									sleep 1
									break
								fi
							done
						else 
							while true; do
								sed -i "s/$pdb,1/$pdb,2/" "$arquivo_csv_2"
								if [ $? -eq 0 ]; then
									sleep 1
									break
								fi
								done
								while true; do
								sed -i "s/$ip,Ocupado.*/$ip,Livre,/" "$arquivo_csv_1"
								if [ $? -eq 0 ]; then
									sleep 1
									break
								fi
								done
						fi
						
					) &
					fi
				fi

				break # Interrompe o primeiro loop externo
			fi
		done
		#break
	#fi
done
