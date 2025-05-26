import random
from collections import Counter
import os
import argparse
import math
import numpy as np

def leggi_file(nome_file):
    """
    Legge il file di input e restituisce una lista di tuple con i 15 numeri.
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
                numeri = list(map(int, dati[2:17]))  # Prende i 15 numeri dalla riga
                if len(numeri) == 15:
                    estrazioni.append(tuple(numeri))
                else:
                    print(f"Linea ignorata per formato non valido: {linea.strip()}")
            except ValueError:
                print(f"Errore di conversione nei numeri: {linea.strip()}")
    return estrazioni


def calcola_probabilita_combinatoria(estrazioni):
    """
    Calcola le probabilità combinatorie per ogni estrazione osservata.
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
    Applica un modello Bayesiano con smoothing per stimare le probabilità delle estrazioni.
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


def genera_numeri_aleatori(estrazioni, n_simulazioni=100000, smoothing=0.01):
    """
    Genera simulazioni di estrazioni casuali per calcolare le probabilità delle estrazioni tramite Monte Carlo,
    con applicazione del smoothing per evitare probabilità estremamente basse.
    """
    conteggi = Counter()
    tutti_numeri = [numero for estrazione in estrazioni for numero in estrazione]
    spazio_probabilistico = Counter(tutti_numeri)
    totale = sum(spazio_probabilistico.values())
    
    # Calcolare la probabilità di ciascun numero, con l'aggiunta del smoothing
    probabilita = {num: (spazio_probabilistico[num] + smoothing) / (totale + smoothing * len(spazio_probabilistico)) 
                   for num in spazio_probabilistico}

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
        ensemble[estrazione] = (p1 + p2 + p3) / 3  # Media semplice; modificare i pesi se necessario

    return ensemble


def stampa_top(prob_dict, top_n=1, titolo=""):
    """
    Stampa le prime top_n estrazioni in base alla probabilità.
    """
    estrazioni_ordinate = sorted(prob_dict.items(), key=lambda x: x[1], reverse=True)
    if titolo:
        print(f"\n{titolo}")
    for estrazione, prob in estrazioni_ordinate[:top_n]:
        print(f"  {estrazione}: {prob:.10f}")


def main():
    parser = argparse.ArgumentParser(
        description="Analisi di estrazioni con tecniche Monte Carlo, combinatorie, Bayesiane ed Ensemble."
    )
    parser.add_argument("nome_file", type=str, help="Il nome del file contenente le estrazioni.")
    parser.add_argument("n_simulazioni", type=int, help="Numero di simulazioni Monte Carlo da eseguire.")
    parser.add_argument("--alpha", type=float, default=1, help="Parametro di smoothing per il modello Bayesiano (default: 1)")
    parser.add_argument("--top", type=int, default=1, help="Numero di risultati da visualizzare per ciascun metodo")
    parser.add_argument("--smoothing", type=float, default=0.01, help="Fattore di smoothing per Monte Carlo (default: 0.01)")
    args = parser.parse_args()

    nome_file = args.nome_file
    n_simulazioni = args.n_simulazioni
    alpha = args.alpha
    top_n = args.top
    smoothing = args.smoothing

    estrazioni = leggi_file(nome_file)
    if not estrazioni:
        print("Nessuna estrazione valida trovata nel file.")
        return

    # Metodo combinatorio
    p_comb = normalizza_probabilita(calcola_probabilita_combinatoria(estrazioni))
    stampa_top(p_comb, top_n, "La quindicina più probabile (Combinatorio):")

    # Modello bayesiano
    p_bayes = normalizza_probabilita(modello_bayesiano(estrazioni, alpha))
    stampa_top(p_bayes, top_n, "La quindicina più probabile (Bayesiano):")

    # Simulazioni Monte Carlo con smoothing
    p_mc = normalizza_probabilita(genera_numeri_aleatori(estrazioni, n_simulazioni, smoothing))
    stampa_top(p_mc, top_n, "La quindicina più probabile (Monte Carlo):")

    # Ensemble dei metodi
    p_ensemble = normalizza_probabilita(modello_ensemble(estrazioni, alpha, n_simulazioni, smoothing))
    stampa_top(p_ensemble, top_n, "La quindicina più probabile (Ensemble):")

    # Stampa dei 15 numeri con probabilità più alta (Ensemble)
    estrazione_top_ensemble = sorted(p_ensemble.items(), key=lambda x: x[1], reverse=True)[:15]
    print("\nI 15 numeri con la probabilità più alta (Ensemble):")
    for i, (estrazione, prob) in enumerate(estrazione_top_ensemble, 1):
        print(f"{i}: {estrazione} con probabilità {prob:.10f}")


if __name__ == "__main__":
    main()

