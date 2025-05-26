import random
from collections import Counter
import os
import argparse
import math
import numpy as np

def leggi_file(nome_file):
    """
    Legge il file e restituisce una lista di liste da 15 numeri (una per ogni estrazione).
    Considera solo i numeri tra 1 e 25.
    """
    estrazioni = []
    if not os.path.exists(nome_file):
        print(f"Errore: il file '{nome_file}' non esiste.")
        return estrazioni

    with open(nome_file, 'r', encoding='utf-8') as file:
        for linea in file:
            dati = linea.strip().split()
            if len(dati) < 17:
                continue  # Salta righe malformate

            try:
                numeri = list(map(int, dati[2:17]))  # Prendi solo i 15 numeri
                # Considera solo numeri tra 1 e 25
                numeri = [num for num in numeri if 1 <= num <= 25]
                if len(numeri) == 15:
                    estrazioni.append(numeri)
            except ValueError:
                print(f"Errore di conversione nei numeri: {linea.strip()}")

    return estrazioni

def calcola_probabilita_combinatoria(estrazioni):
    """
    Calcola la probabilità combinatoria per ogni numero tra 1 e 25.
    Considera solo i numeri presenti nelle estrazioni.
    """
    tutti_numeri = [num for estrazione in estrazioni for num in estrazione]
    spazio_probabilistico = Counter(tutti_numeri)
    totale = sum(spazio_probabilistico.values())

    # Considera solo i numeri da 1 a 25
    return {num: spazio_probabilistico.get(num, 0) / totale for num in range(1, 26)}

def modello_bayesiano(estrazioni, alpha):
    """
    Calcola la probabilità Bayesiana per ogni numero tra 1 e 25.
    Considera solo i numeri presenti nelle estrazioni.
    """
    tutti_numeri = [num for estrazione in estrazioni for num in estrazione]
    spazio_probabilistico = Counter(tutti_numeri)
    totale = sum(spazio_probabilistico.values())
    num_unici = len(spazio_probabilistico)

    # Considera solo i numeri da 1 a 25
    return {
        num: (spazio_probabilistico.get(num, 0) + alpha) / (totale + alpha * num_unici)
        for num in range(1, 26)
    }

def genera_probabilita_monte_carlo(estrazioni, n_simulazioni=100000):
    """
    Usa simulazioni Monte Carlo per stimare le probabilità dei singoli numeri tra 1 e 25.
    Considera solo i numeri presenti nelle estrazioni.
    """
    conteggi = Counter()
    tutti_numeri = [num for estrazione in estrazioni for num in estrazione]
    spazio_probabilistico = Counter(tutti_numeri)
    totale = sum(spazio_probabilistico.values())

    chiavi = list(spazio_probabilistico.keys())
    pesi = [spazio_probabilistico[num] / totale for num in chiavi]

    for _ in range(n_simulazioni):
        estrazione = random.choices(chiavi, weights=pesi, k=15)
        conteggi.update(estrazione)

    # Considera solo i numeri da 1 a 25
    return {num: conteggi.get(num, 0) / (n_simulazioni * 15) for num in range(1, 26)}

def normalizza_probabilita(prob_dict):
    """
    Normalizza le probabilità in modo che la loro somma sia 1.
    """
    totale = sum(prob_dict.values())
    if totale == 0:
        return prob_dict
    return {k: v / totale for k, v in prob_dict.items()}

def modello_ensemble(estrazioni, alpha, n_simulazioni):
    """
    Combina le probabilità di tutti i numeri tramite i tre metodi.
    Considera solo i numeri da 1 a 25.
    """
    p_comb = normalizza_probabilita(calcola_probabilita_combinatoria(estrazioni))
    p_bayes = normalizza_probabilita(modello_bayesiano(estrazioni, alpha))
    p_mc = normalizza_probabilita(genera_probabilita_monte_carlo(estrazioni, n_simulazioni))

    tutti_numeri = set(p_comb) | set(p_bayes) | set(p_mc)
    ensemble = {}
    for num in tutti_numeri:
        ensemble[num] = (p_comb.get(num, 0) + p_bayes.get(num, 0) + p_mc.get(num, 0)) / 3
    return ensemble

def stampa_top_numeri(prob_dict, top_n=15, titolo=""):
    """
    Stampa i numeri in ordine crescente (indipendentemente dalla probabilità).
    """
    # Ordina solo per numero in ordine crescente (ignorando le probabilità)
    ordinati = sorted(prob_dict.items(), key=lambda x: x[0])  # Ordina per numero

    if titolo:
        print(f"\n{titolo}")
    
    for num, prob in ordinati[:top_n]:
        print(f"  {num:>2}: {prob:.6f}")

def main():
    parser = argparse.ArgumentParser(
        description="Analisi di 15 numeri tramite modelli probabilistici."
    )
    parser.add_argument("nome_file", type=str, help="File contenente le estrazioni da 15 numeri.")
    parser.add_argument("n_simulazioni", type=int, help="Numero di simulazioni Monte Carlo.")
    parser.add_argument("--alpha", type=float, default=1, help="Alpha per Bayes (default: 1)")
    parser.add_argument("--top", type=int, default=15, help="Quanti numeri mostrare (default: 15)")
    args = parser.parse_args()

    estrazioni = leggi_file(args.nome_file)
    if not estrazioni:
        print("Nessuna estrazione valida trovata.")
        return

    # Metodo combinatorio
    p_comb = normalizza_probabilita(calcola_probabilita_combinatoria(estrazioni))
    stampa_top_numeri(p_comb, args.top, "Combinatorio:")

    # Modello bayesiano
    p_bayes = normalizza_probabilita(modello_bayesiano(estrazioni, args.alpha))
    stampa_top_numeri(p_bayes, args.top, "Bayesiano:")

    # Simulazioni Monte Carlo
    p_mc = normalizza_probabilita(genera_probabilita_monte_carlo(estrazioni, args.n_simulazioni))
    stampa_top_numeri(p_mc, args.top, "Monte Carlo:")

    # Ensemble dei metodi
    p_ensemble = normalizza_probabilita(modello_ensemble(estrazioni, args.alpha, args.n_simulazioni))
    stampa_top_numeri(p_ensemble, args.top, "Ensemble:")

if __name__ == "__main__":
    main()

