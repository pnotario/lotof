import random
import math
import os
from collections import Counter
import argparse
import numpy as np

# Funzione per leggere il file di input
def leggi_file(nome_file):
    cinquine = []
    if not os.path.exists(nome_file):
        print(f"Errore: il file '{nome_file}' non esiste.")
        return cinquine

    with open(nome_file, 'r', encoding='utf-8') as file:
        for linea in file:
            dati = linea.strip().split()
            try:
                # La data nella prima colonna viene ignorata
                numeri = list(map(int, dati[2:]))  # I numeri sono dalla terza colonna in poi
                if len(numeri) == 15:
                    cinquine.append(tuple(numeri))
                else:
                    print(f"Linea ignorata per formato non valido: {linea.strip()}")
            except ValueError:
                print(f"Errore di conversione nei numeri: {linea.strip()}")
    return cinquine

# Metodo combinatorio per calcolare le probabilità
def calcola_probabilita_combinatoria(cinquine):
    tutti_numeri = [numero for cinquina in cinquine for numero in cinquina]
    spazio_probabilistico = Counter(tutti_numeri)
    totale = sum(spazio_probabilistico.values())
    probabilita_numeri = {num: spazio_probabilistico[num] / totale for num in spazio_probabilistico}
    probabilita_cinquine = {}
    for cinquina in cinquine:
        p = math.prod(probabilita_numeri[num] for num in cinquina)
        probabilita_cinquine[cinquina] = p
    return probabilita_cinquine

# Metodo bayesiano per calcolare le probabilità con smoothing
def modello_bayesiano(cinquine, alpha):
    tutti_numeri = [numero for cinquina in cinquine for numero in cinquina]
    spazio_probabilistico = Counter(tutti_numeri)
    totale = sum(spazio_probabilistico.values())
    num_unici = len(spazio_probabilistico)
    probabilita_posteriori = {}
    for num in spazio_probabilistico:
        probabilita_posteriori[num] = (spazio_probabilistico[num] + alpha) / (totale + alpha * num_unici)
    probabilita_cinquine = {}
    for cinquina in cinquine:
        p = math.prod(probabilita_posteriori[num] for num in cinquina)
        probabilita_cinquine[cinquina] = p
    return probabilita_cinquine

# Metodo Monte Carlo per calcolare le probabilità
def genera_numeri_aleatori(cinquine, n_simulazioni=100000):
    conteggi = Counter()
    tutti_numeri = [numero for cinquina in cinquine for numero in cinquina]
    spazio_probabilistico = Counter(tutti_numeri)
    totale = sum(spazio_probabilistico.values())
    probabilita = {num: spazio_probabilistico[num] / totale for num in spazio_probabilistico}
    chiavi = list(probabilita.keys())
    pesi = list(probabilita.values())
    for _ in range(n_simulazioni):
        estrazione = tuple(sorted(random.choices(chiavi, weights=pesi, k=15)))  # Estrazione di 15 numeri
        conteggi[estrazione] += 1
    probabilita_cinquine = {cinquina: conteggio / n_simulazioni for cinquina, conteggio in conteggi.items()}
    return probabilita_cinquine

# Normalizzazione delle probabilità
def normalizza_probabilita(prob_dict):
    totale = sum(prob_dict.values())
    if totale == 0:
        return prob_dict
    return {k: v / totale for k, v in prob_dict.items()}

# Metodo Ensemble che combina tutti i metodi
def modello_ensemble(cinquine, alpha, n_simulazioni):
    p_comb = normalizza_probabilita(calcola_probabilita_combinatoria(cinquine))
    p_bayes = normalizza_probabilita(modello_bayesiano(cinquine, alpha))
    p_mc = normalizza_probabilita(genera_numeri_aleatori(cinquine, n_simulazioni))
    tutte_cinquine = set(p_comb.keys()) | set(p_bayes.keys()) | set(p_mc.keys())
    ensemble = {}
    for cinquina in tutte_cinquine:
        p1 = p_comb.get(cinquina, 0)
        p2 = p_bayes.get(cinquina, 0)
        p3 = p_mc.get(cinquina, 0)
        ensemble[cinquina] = (p1 + p2 + p3) / 3  # Media semplice; modificare i pesi se necessario
    return ensemble

# Funzione per salvare le probabilità calcolate su un file
def salva_probabilita_su_file(nome_file, prob_dict, titolo="Probabilità"):
    with open(nome_file, 'w', encoding='utf-8') as f:
        f.write(f"{titolo}\n")
        for n, prob in prob_dict.items():
            if isinstance(n, tuple):
                n = ', '.join(map(str, n))  # Converti la tupla in stringa separata da virgole
            f.write(f"{n}: {prob:.8f}\n")

# Funzione per stampare i top N risultati
def stampa_top(prob_dict, top_n=1, titolo=""):
    cinquine_ordinate = sorted(prob_dict.items(), key=lambda x: x[1], reverse=True)
    if titolo:
        print(f"\n{titolo}")
    for cinquina, prob in cinquine_ordinate[:top_n]:
        cinquina_ordinata = tuple(sorted(cinquina))  # Ordinamento crescente
        print(f"  {cinquina_ordinata}: {prob:.10f}")

# Funzione principale
def main():
    parser = argparse.ArgumentParser(description="Analisi di 15 numeri con tecniche Monte Carlo, combinatorie, Bayesiane ed Ensemble.")
    parser.add_argument("nome_file", type=str, help="Il nome del file contenente le estrazioni di 15 numeri.")
    parser.add_argument("n_simulazioni", type=int, help="Numero di simulazioni Monte Carlo da eseguire.")
    parser.add_argument("--alpha", type=float, default=1, help="Parametro di smoothing per il modello Bayesiano (default: 1)")
    parser.add_argument("--top", type=int, default=15, help="Numero di risultati da visualizzare per ciascun metodo")
    args = parser.parse_args()

    nome_file = args.nome_file
    n_simulazioni = args.n_simulazioni
    alpha = args.alpha
    top_n = args.top

    # Leggi il file delle estrazioni
    cinquine = leggi_file(nome_file)
    if not cinquine:
        print("Nessuna cinquina valida trovata nel file.")
        return

    # Calcola i risultati per ogni metodo
    p_comb = normalizza_probabilita(calcola_probabilita_combinatoria(cinquine))
    p_bayes = normalizza_probabilita(modello_bayesiano(cinquine, alpha))
    p_mc = normalizza_probabilita(genera_numeri_aleatori(cinquine, n_simulazioni))

    # Stampa i risultati per ogni metodo
    stampa_top(p_comb, top_n, "Probabilità Combinatorie:")
    stampa_top(p_bayes, top_n, "Probabilità Bayesiane:")
    stampa_top(p_mc, top_n, "Probabilità Monte Carlo:")

    # Calcola il modello Ensemble
    p_ensemble = modello_ensemble(cinquine, alpha, n_simulazioni)

    # Stampa il risultato dell'Ensemble con ordinamento crescente
    stampa_top(p_ensemble, top_n, "Probabilità Ensemble:")

    # Salva i risultati nel file
    salva_probabilita_su_file(f"probabilita_ensemble.txt", p_ensemble, "Metodo Ensemble")

if __name__ == "__main__":
    main()

