import random
from collections import Counter
import os
import argparse
import math

def leggi_file(nome_file):
    """
    Legge il file di input e restituisce una lista di tuple da 15 numeri.
    Il file deve avere colonne: Concorso, Data, Num1, ..., Num15
    """
    estrazioni = []
    if not os.path.exists(nome_file):
        print(f"Errore: il file '{nome_file}' non esiste.")
        return estrazioni

    with open(nome_file, 'r', encoding='utf-8') as file:
        for linea in file:
            dati = linea.strip().split()
            try:
                numeri = list(map(int, dati[2:]))  # Salta concorso e data
                if len(numeri) == 15:
                    estrazioni.append(tuple(numeri))
                else:
                    print(f"Linea ignorata (non ha 15 numeri): {linea.strip()}")
            except ValueError:
                print(f"Errore nei dati: {linea.strip()}")
    return estrazioni

def calcola_probabilita_combinatoria(estrazioni):
    tutti_numeri = [num for estrazione in estrazioni for num in estrazione]
    conteggio = Counter(tutti_numeri)
    totale = sum(conteggio.values())
    return {n: conteggio[n] / totale for n in range(1, 26)}

def modello_bayesiano(estrazioni, alpha):
    tutti_numeri = [num for estrazione in estrazioni for num in estrazione]
    conteggio = Counter(tutti_numeri)
    totale = sum(conteggio.values())
    k = 25  # numeri da 1 a 25
    return {n: (conteggio.get(n, 0) + alpha) / (totale + alpha * k) for n in range(1, 26)}

def genera_probabilita_monte_carlo(estrazioni, n_simulazioni):
    tutti_numeri = [num for estrazione in estrazioni for num in estrazione]
    spazio_prob = Counter(tutti_numeri)
    totale = sum(spazio_prob.values())
    probabilita = {n: spazio_prob.get(n, 0) / totale for n in range(1, 26)}

    chiavi = list(probabilita.keys())
    pesi = list(probabilita.values())
    conteggi = Counter()

    for _ in range(n_simulazioni):
        estrazione = random.choices(chiavi, weights=pesi, k=15)
        for n in estrazione:
            conteggi[n] += 1

    return {n: conteggi[n] / (n_simulazioni * 15) for n in range(1, 26)}

def normalizza_probabilita(prob_dict):
    totale = sum(prob_dict.values())
    return {k: v / totale for k, v in prob_dict.items()}

def modello_ensemble(estrazioni, alpha, n_simulazioni):
    p_comb = normalizza_probabilita(calcola_probabilita_combinatoria(estrazioni))
    p_bayes = normalizza_probabilita(modello_bayesiano(estrazioni, alpha))
    p_mc = normalizza_probabilita(genera_probabilita_monte_carlo(estrazioni, n_simulazioni))

    ensemble = {}
    for n in range(1, 26):
        ensemble[n] = (p_comb.get(n, 0) + p_bayes.get(n, 0) + p_mc.get(n, 0)) / 3
    return normalizza_probabilita(ensemble)

def stampa_top_15(prob_dict):
    print("\nI 15 numeri più probabili (metodo Ensemble):")
    top_15 = sorted(prob_dict.items(), key=lambda x: x[1], reverse=True)[:15]
    top_15_sorted = sorted([num for num, _ in top_15])
    print("Numeri selezionati:", top_15_sorted)
    return top_15_sorted

def analizza_top_con_estrazioni(top_numeri, estrazioni):
    tutti_numeri = [num for estrazione in estrazioni for num in estrazione]
    conteggio = Counter(tutti_numeri)
    totale = len(estrazioni) * 15  # ogni riga ha 15 numeri

    print("\nAnalisi dei numeri Ensemble rispetto alle estrazioni storiche:")
    for numero in sorted(top_numeri):
        freq = conteggio.get(numero, 0)
        prob = freq / totale
        print(f"Numero {numero:2d} - Frequenza: {freq:4d} - Probabilità: {prob:.5f}")

def main():
    parser = argparse.ArgumentParser(description="Analisi Ensemble di 15 numeri da 1 a 25 su base storica.")
    parser.add_argument("nome_file", type=str, help="File contenente le estrazioni")
    parser.add_argument("n_simulazioni", type=int, help="Numero simulazioni Monte Carlo")
    parser.add_argument("--alpha", type=float, default=1, help="Alpha smoothing (default=1)")
    args = parser.parse_args()

    estrazioni = leggi_file(args.nome_file)
    if not estrazioni:
        print("Nessuna estrazione valida trovata.")
        return

    prob_ensemble = modello_ensemble(estrazioni, args.alpha, args.n_simulazioni)
    top_15 = stampa_top_15(prob_ensemble)
    analizza_top_con_estrazioni(top_15, estrazioni)

if __name__ == "__main__":
    main()
