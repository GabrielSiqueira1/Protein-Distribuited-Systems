#!/bin/bash

# Para a distribuição dos arquivos e a verificação do seu sucesso por parte da máquina central, devemos utilizar os ip's das máquinas em um vetor, bem como um vetor de arquivos. {Naming}

chave="chave1234567890ab"

atualizar_config(){

	# Adiciona as propriedades por meio de um arquivo
	local config_file="config.txt"
	local temp_ip_computadores=()
	local temp_pdbs=()

	while IFS= read -r line; do

		if [[ $line =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
			temp_ip_computadores+=("$line")
		else
			temp_pdbs+=("$line")
		fi

	done < "$config_file"

	# Em um escalonamento dinâmico, devemos verificar se houve alteração no arquivo .txt
	if [[ "${temp_ip_computadore[*]}" != "${ip_computadores[*]}" || "${temp_pdbs[*]}" != "${pdbs[*]}" ]]; then
		ip_computadores=("${temp_ip_computadores[@]}")
        pdbs=("${temp_pdbs[@]}")
        #echo "Os vetores foram atualizados."

        # Atualiza o arquivo CSV com as novas entradas
        for new_ip in "${temp_ip_computadores[@]}"; do
            if ! grep -q "$new_ip" "$arquivo_csv_1"; then
                echo "$new_ip,Livre," >> "$arquivo_csv_1"
            fi
        done

        for new_pdb in "${temp_pdbs[@]}"; do
            if ! grep -q "$new_pdb" "$arquivo_csv_2"; then
                echo "$new_pdb,0," >> "$arquivo_csv_2"
            fi
        done
	fi
}

ip_computadores=()
pdbs=()

# Para a coordenação dos processos, criamos dois arquivos .csv cujo o propósito é a identificação do estado de uma máquina e de um arquivo. A máquina poderá estar livre ou ocupada, enquanto o arquivo pode estar como processado ou não. {Coordenação}
arquivo_csv_1="estado_maquina.csv"
arquivo_csv_2="estado_arquivo.csv"

if [ ! -e $arquivo_csv_1 ];then
	echo "IP,Estado,Arquivo,Comunicação" > "$arquivo_csv_1"
	echo "Arquivo,Estado,IP" > "$arquivo_csv_2"
fi

# Inicialização dos arquivos
atualizar_config

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
				indice_arquivo=$((indice_arquivo + 1025))
				# Para que o computador realize sua tarefa este deverá ter uma porta aberta para receber o arquivo da central {Comunicação}

				sleep 1
				echo "$indice_arquivo" | nc -q 5 "$ip" 9998 # Envio da porta de retorno
					if [ $? -eq 0 ]; then
						sleep 1
						echo "$pdb" | nc "$ip" 9998 -q 5
						# Criptografia do arquivo {Segurança}
						tar cz "$pdb" | openssl enc -aes-256-cbc -a -k "$chave" -pbkdf2 | nc -q 5 "$ip" 9998
						# nc "$ip" 9998 -q 5 < "$pdb" 
						echo "Enviado"
			
						sed -i "s/$ip,Livre/$ip,Ocupado,$pdb/" "$arquivo_csv_1" # Substituição do valor de estado do ip
						sed -i "s/$pdb,0/$pdb,1,$ip/" "$arquivo_csv_2" # Substituição do valor de estado do arquivo para processando														sleep 1
				
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
								sed -i "s/$ip,Ocupado,$pdb,/$ip,Ocupado,$pdb,$resposta, /" "$arquivo_csv_1"
							else
								sed -i "s/$ip,Ocupado,$pdb,/$ip,Ocupado,$pdb,$resposta, /" "$arquivo_csv_1"
								while true; do
									nc -l -p $indice_arquivo > "arquivo_$ip-$pdb.txt"
									if [ $? -eq 0 ]; then
										break
									fi
								done
								break
							fi	
						done

						# Com a conclusão do processo é necessário alterar os arquivos .csv
						if [ "$timeout" -eq 0 ]; then
							echo "Arquivo não concluído"
							while true; do
								sed -i "s/$pdb,1,/$pdb,0,/" "$arquivo_csv_2"
								if [ $? -eq 0 ]; then
									break
								fi
							done
						else 
							while true; do
								sed -i "s/$pdb,1,/$pdb,2,/" "$arquivo_csv_2"
								if [ $? -eq 0 ]; then
									break
								fi
							done
							while true; do
								sed -i "s/$ip,Ocupado,/$ip,Livre,/" "$arquivo_csv_1"
								if [ $? -eq 0 ]; then
									break
								fi
							done
						fi
						
					) &
					fi
				
			fi
			break # Interrompe o primeiro loop externo
		fi
		atualizar_config
	done
done
