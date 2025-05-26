import random
from collections import Counter
import os
import argparse
import math
import numpy as np
import time

def leggi_file(nome_file):
    """
    Legge il file di input e restituisce una lista di tuple a 15 numeri.
    Il file deve avere, per ogni riga, una data (ignorata) seguita da 15 numeri.
    """
    estrazioni = []
    if not os.path.exists(nome_file):
        print(f"Errore: il file '{nome_file}' non esiste.")
        return estrazioni

    with open(nome_file, 'r', encoding='utf-8') as file:
        for linea in file:
            dati = linea.strip().split()
            try:
                numeri = list(map(int, dati[2:]))  # Prende solo i numeri (escludendo la data)
                if len(numeri) == 15:
                    estrazioni.append(tuple(numeri))
                else:
                    print(f"Linea ignorata per formato non valido: {linea.strip()}")
            except ValueError:
                print(f"Errore di conversione nei numeri: {linea.strip()}")
    return estrazioni


def calcola_probabilita_combinatoria(estrazioni):
    """
    Calcola le probabilità combinatorie per ogni numero osservato nelle estrazioni.
    """
    tutti_numeri = [numero for estrazione in estrazioni for numero in estrazione]
    spazio_probabilistico = Counter(tutti_numeri)

    totale = sum(spazio_probabilistico.values())
    probabilita_numeri = {num: spazio_probabilistico[num] / totale for num in spazio_probabilistico}

    probabilita_estrazioni = {}
    for estrazione in estrazioni:
        p = math.prod(probabilita_numeri[num] for num in estrazione)
        probabilita_estrazioni[estrazione] = p

    return probabilita_estrazioni


def modello_bayesiano(estrazioni, alpha):
    """
    Applica un modello Bayesiano con smoothing per stimare le probabilità.
    """
    tutti_numeri = [numero for estrazione in estrazioni for numero in estrazione]
    spazio_probabilistico = Counter(tutti_numeri)
    totale = sum(spazio_probabilistico.values())
    num_unici = len(spazio_probabilistico)

    probabilita_posteriori = {}
    for num in spazio_probabilistico:
        probabilita_posteriori[num] = (spazio_probabilistico[num] + alpha) / (totale + alpha * num_unici)

    probabilita_estrazioni = {}
    for estrazione in estrazioni:
        p = math.prod(probabilita_posteriori[num] for num in estrazione)
        probabilita_estrazioni[estrazione] = p

    return probabilita_estrazioni


def genera_numeri_aleatori(estrazioni, n_simulazioni=100000, smoothing=0):
    """
    Simula estrazioni casuali per calcolare le probabilità delle estrazioni tramite Monte Carlo.
    """
    conteggi = Counter()
    tutti_numeri = [numero for estrazione in estrazioni for numero in estrazione]
    spazio_probabilistico = Counter(tutti_numeri)
    totale = sum(spazio_probabilistico.values())
    probabilita = {num: (spazio_probabilistico[num] + smoothing) / (totale + smoothing * 25) for num in spazio_probabilistico}

    chiavi = list(probabilita.keys())
    pesi = list(probabilita.values())

    for _ in range(n_simulazioni):
        estrazione = tuple(sorted(random.choices(chiavi, weights=pesi, k=15)))
        conteggi[estrazione] += 1

    # Converti i conteggi in probabilità stimate
    probabilita_estrazioni = {estrazione: conteggio / n_simulazioni for estrazione, conteggio in conteggi.items()}
    return probabilita_estrazioni


def normalizza_probabilita(prob_dict):
    """
    Normalizza le probabilità in modo che la loro somma sia 1.
    """
    totale = sum(prob_dict.values())
    if totale == 0:
        return prob_dict
    return {k: v / totale for k, v in prob_dict.items()}


def modello_ensemble(estrazioni, alpha, n_simulazioni, smoothing):
    """
    Combina i tre metodi (combinatorio, bayesiano e Monte Carlo) per ottenere una stima ensemble.
    Le probabilità vengono normalizzate e poi combinate mediante media semplice (o pesata).
    """
    p_comb = normalizza_probabilita(calcola_probabilita_combinatoria(estrazioni))
    p_bayes = normalizza_probabilita(modello_bayesiano(estrazioni, alpha))
    p_mc = normalizza_probabilita(genera_numeri_aleatori(estrazioni, n_simulazioni, smoothing))

    tutte_estrazioni = set(p_comb.keys()) | set(p_bayes.keys()) | set(p_mc.keys())
    ensemble = {}
    for estrazione in tutte_estrazioni:
        p1 = p_comb.get(estrazione, 0)
        p2 = p_bayes.get(estrazione, 0)
        p3 = p_mc.get(estrazione, 0)
        ensemble[estrazione] = (p1 + p2 + p3) / 3  # Media semplice

    return ensemble


def stampa_top(prob_dict, top_n=15, titolo=""):
    """
    Stampa le prime top_n estrazioni in base alla probabilità, ordinando i numeri di ciascuna estrazione in ordine crescente.
    """
    estrazioni_ordinate = sorted(prob_dict.items(), key=lambda x: x[1], reverse=True)
    if titolo:
        print(f"\n{titolo}")
    for estrazione, prob in estrazioni_ordinate[:top_n]:
        # Ordina i numeri all'interno di ciascuna estrazione prima di stamparli
        estrazione_ordinata = tuple(sorted(estrazione))
        print(f"  Estrazione: {estrazione_ordinata}, Probabilità: {prob:.10f}")


def main():
    parser = argparse.ArgumentParser(
        description="Analisi di estrazioni con tecniche Monte Carlo, combinatorie, Bayesiane ed Ensemble."
    )
    parser.add_argument("nome_file", type=str, help="Il nome del file contenente le estrazioni.")
    parser.add_argument("n_simulazioni", type=int, help="Numero di simulazioni Monte Carlo da eseguire.")
    parser.add_argument("--alpha", type=float, default=1, help="Parametro di smoothing per il modello Bayesiano (default: 1)")
    parser.add_argument("--smoothing", type=float, default=0.01, help="Smoothing per il modello Monte Carlo (default: 0.01)")
    parser.add_argument("--top", type=int, default=15, help="Numero di risultati da visualizzare per ciascun metodo")
    args = parser.parse_args()

    nome_file = args.nome_file
    n_simulazioni = args.n_simulazioni
    alpha = args.alpha
    smoothing = args.smoothing
    top_n = args.top

    estrazioni = leggi_file(nome_file)
    if not estrazioni:
        print("Nessuna estrazione valida trovata nel file.")
        return

    # Metodo ensemble
    p_ensemble = normalizza_probabilita(modello_ensemble(estrazioni, alpha, n_simulazioni, smoothing))
    stampa_top(p_ensemble, top_n, "Top 15 estrazioni con probabilità più alta (Ensemble):")


if __name__ == "__main__":
    main()

