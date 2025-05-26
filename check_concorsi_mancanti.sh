#set -x
#!/bin/bash

# Nome del file che contiene i concorsi
FILE="./dat/dati.txt"
# Leggi i numeri dei concorsi dal file
NUMERI_CONCORSI=($(awk '{print $1}' "$FILE"))

# Trova il minimo e il massimo numero di concorso
MIN_CONCORSO=${NUMERI_CONCORSI[0]}
MAX_CONCORSO=${NUMERI_CONCORSI[-1]}

# Controlla i concorsi mancanti
for ((i=MAX_CONCORSO; i<=MIN_CONCORSO; i++)); do
    if [[ ! " ${NUMERI_CONCORSI[@]} " =~ " $i " ]]; then
        echo "Concorso $i mancante"
    fi
done
