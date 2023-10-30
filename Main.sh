#!/bin/bash

# Defina as informações das máquinas e arquivos
machines=("192.168.0.57")
files=("teste.ent")

# Crie o arquivo CSV para rastrear o estado de ocupação das máquinas
csvfile="machine_status.csv"

# Inicialize o arquivo CSV com todas as máquinas livres
echo "Machine,Status" > "$csvfile"
for machine in "${machines[@]}"; do
  echo "$machine,Free" >> "$csvfile"
done

# Função para verificar a disponibilidade de uma máquina
is_machine_free() {
  local machine="$1"
  local status=$(grep "$machine" "$csvfile" | cut -d',' -f2)
  [[ "$status" == "Free" ]]
}

# Loop para distribuir os arquivos para as máquinas
for file in "${files[@]}"; do
  for machine in "${machines[@]}"; do
    if is_machine_free "$machine"; then
      # Marque a máquina como ocupada no CSV
      sed -i "s/$machine,Free/$machine,Busy/" "$csvfile"
      
      # Distribua o arquivo para a máquina
      echo "Distribuindo $file para $machine"
      # Comando para copiar o arquivo para a máquina, por exemplo: scp "$file" "$machine:/caminho/para/destino/"
      cat "$file" | nc "$machine" 12345
      # Inicie um processo em segundo plano para monitorar se a máquina terminou
      (
        # Aguarde até que a máquina envie o arquivo de log ou até que 20 minutos se passem
        timeout=1200 # 20 minutos em segundos
        while [ "$timeout" -gt 0 ]; do
          if [ -e "$machine-log.txt" ]; then
            # Arquivo de log recebido, processo concluído
            echo "Arquivo de log recebido de $machine"
            # Comando para copiar o arquivo de log para o computador central, por exemplo: scp "$machine:/caminho/para/log.txt" "/caminho/para/salvar/log.txt"
            break
          fi
          sleep 1
          timeout=$((timeout - 1))
        done
        
        # Marque a máquina como livre após a conclusão do processo
        # Comando para marcar a máquina como livre no CSV
        sed -i "s/$machine,Busy/$machine,Free/" "$csvfile"
        
        # Verifique se o arquivo de log foi recebido, senão, devolva o arquivo ao vetor 'files'
        if [ ! -e "$machine-log.txt" ]; then
          echo "Arquivo não concluído, devolvendo $file ao vetor 'files'"
          files=("$file" "${files[@]}")
        fi
      ) &
      
      break
    fi
  done
done
