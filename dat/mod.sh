#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Uso: $0 <file_input>"
  exit 1
fi

input="$1"

# Array con i mesi in italiano
mesi=(Gennaio Febbraio Marzo Aprile Maggio Giugno Luglio Agosto Settembre Ottobre Novembre Dicembre)

while IFS= read -r line; do
  # Estrai prima e seconda colonna
  id=$(echo "$line" | awk '{print $1}')
  data=$(echo "$line" | awk '{print $2}')
  
  # Estrai giorno, mese e anno dalla data
  giorno=$(echo "$data" | cut -d'/' -f1)
  mese_num=$(echo "$data" | cut -d'/' -f2)
  anno=$(echo "$data" | cut -d'/' -f3)
  
  mese_idx=$((10#$mese_num - 1))
  mese_str=${mesi[$mese_idx]}
  
  # Crea la data riformattata
  nuova_data="${giorno}${mese_str}${anno}"
  
  # Unisci prima e seconda colonna con underscore
  nuova_prima_colonna="${id}_${nuova_data}"
  
  # Estrai il resto delle colonne (dalla terza in poi)
  resto=$(echo "$line" | cut -f3-)
  
  # Stampa la nuova riga con la prima colonna unita e il resto
  echo -e "${nuova_prima_colonna}\t${resto}"
done < "$input"

