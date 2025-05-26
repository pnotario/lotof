import matplotlib.pyplot as plt
from collections import Counter
import numpy as np

# Leggi i numeri dalle sequenze nel file dati.txt
sequenze = []
with open('dati.txt', 'r') as file:
    for riga in file:
        # Ignora la prima e la seconda colonna (ID e data)
        numeri = riga.strip().split('\t')[2:]
        sequenze.append([int(numero) for numero in numeri])

# Unisci tutte le liste in una sola
tutti_numeri = [numero for sequenza in sequenze for numero in sequenza]

# Conta la frequenza di ogni numero
frequenze = Counter(tutti_numeri)

# Crea una figura con 5 sottoplot
fig, axs = plt.subplots(5, 1, figsize=(10, 25))  # Aumenta la dimensione verticale

# Grafico a barre per la frequenza dei numeri
axs[0].bar(frequenze.keys(), frequenze.values())
axs[0].set_xlabel('Numero', fontsize=12)
axs[0].set_ylabel('Frequenza', fontsize=12)
axs[0].set_title('Frequenza dei Numeri', fontsize=14)
axs[0].tick_params(axis='x', rotation=90, labelsize=10)

# Grafico a linee per l'andamento dei numeri nel tempo
for i, sequenza in enumerate(sequenze):
    axs[1].plot(sequenza, label=f'Sequenza {i+1}')
axs[1].set_xlabel('Posizione nella Sequenza', fontsize=12)
axs[1].set_ylabel('Valore', fontsize=12)
axs[1].set_title('Andamento dei Numeri nel Tempo', fontsize=14)
axs[1].legend(fontsize=10)

# Grafico a istogramma per la distribuzione dei numeri
axs[2].hist(tutti_numeri, bins=range(min(tutti_numeri), max(tutti_numeri)+2), align='left', rwidth=0.8)
axs[2].set_xlabel('Numero', fontsize=12)
axs[2].set_ylabel('Frequenza', fontsize=12)
axs[2].set_title('Distribuzione dei Numeri', fontsize=14)

# Grafico di probabilità cumulativa (CDF)
valori_ordinati = sorted(tutti_numeri)
prob_cumulativa = np.arange(len(valori_ordinati)) / len(valori_ordinati)
axs[3].plot(valori_ordinati, prob_cumulativa)
axs[3].set_xlabel('Numero', fontsize=12)
axs[3].set_ylabel('Probabilità Cumulativa', fontsize=12)
axs[3].set_title('Probabilità Cumulativa dei Numeri', fontsize=14)

# Grafico a barre con etichette per la frequenza dei numeri
axs[4].bar(frequenze.keys(), frequenze.values())
for i, (numero, frequenza) in enumerate(frequenze.items()):
    axs[4].text(i, frequenza / 2, str(numero), ha='center', va='center', fontsize=8)
axs[4].set_xlabel('Posizione', fontsize=12)
axs[4].set_ylabel('Frequenza', fontsize=12)
axs[4].set_title('Frequenza dei Numeri con Etichette', fontsize=14)
axs[4].tick_params(axis='x', labelbottom=False)

# Layout per evitare sovrapposizioni
plt.tight_layout(pad=2)  # Aggiungi un po' di spazio tra i grafici

plt.show()

