import random
from collections import Counter
import os
import argparse
import math
import numpy as np
from datetime import datetime

def get_timestamp():
    """
    Restituisce un timestamp con il formato YYYYMMDD_HHMMSS.
    """
    return datetime.now().strftime("%Y%m%d_%H%M%S")

def leggi_file(nome_file):
    """
    Legge il file di input e restituisce una lista di tuple di 15 numeri.
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
                # La data nella prima colonna viene ignorata
                numeri = list(map(int, dati[2:]))  # Considera i numeri dal 3° al 17°
                if len(numeri) == 15:
                    estrazioni.append(tuple(numeri))
                else:
                    print(f"Linea ignorata per formato non valido: {linea.strip()}")
            except ValueError:
                print(f"Errore di conversione nei numeri: {linea.strip()}")
    return estrazioni

def calcola_probabilita_combinatoria(estrazioni):
    """
    Calcola le probabilità combinatorie per ogni numero estratto.
    """
    tutti_numeri = [numero for estrazione in estrazioni for numero in estrazione]
    spazio_probabilistico = Counter(tutti_numeri)

    totale = sum(spazio_probabilistico.values())
    probabilita_numeri = {num: spazio_probabilistico[num] / totale for num in spazio_probabilistico}

    return probabilita_numeri

def modello_bayesiano(estrazioni, alpha):
    """
    Applica un modello Bayesiano con smoothing per stimare le probabilità dei numeri.
    """
    tutti_numeri = [numero for estrazione in estrazioni for numero in estrazione]
    spazio_probabilistico = Counter(tutti_numeri)
    totale = sum(spazio_probabilistico.values())
    num_unici = len(spazio_probabilistico)

    probabilita_posteriori = {}
    for num in spazio_probabilistico:
        probabilita_posteriori[num] = (spazio_probabilistico[num] + alpha) / (totale + alpha * num_unici)

    return probabilita_posteriori

def genera_numeri_aleatori(estrazioni, n_simulazioni=100000):
    """
    Genera simulazioni di estrazioni casuali per calcolare le probabilità dei numeri tramite Monte Carlo.
    """
    conteggi = Counter()
    tutti_numeri = [numero for estrazione in estrazioni for numero in estrazione]
    spazio_probabilistico = Counter(tutti_numeri)
    totale = sum(spazio_probabilistico.values())
    probabilita = {num: spazio_probabilistico[num] / totale for num in spazio_probabilistico}

    chiavi = list(probabilita.keys())
    pesi = list(probabilita.values())

    for _ in range(n_simulazioni):
        estrazione = random.choices(chiavi, weights=pesi, k=15)
        conteggi[tuple(sorted(estrazione))] += 1

    probabilita_numeri = {cinquina: conteggio / n_simulazioni for cinquina, conteggio in conteggi.items()}
    return probabilita_numeri

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
    Combina i tre metodi (combinatorio, bayesiano e Monte Carlo) per ottenere una stima ensemble.
    """
    p_comb = normalizza_probabilita(calcola_probabilita_combinatoria(estrazioni))
    p_bayes = normalizza_probabilita(modello_bayesiano(estrazioni, alpha))
    p_mc = normalizza_probabilita(genera_numeri_aleatori(estrazioni, n_simulazioni))

    tutte_cinquine = set(p_comb.keys()) | set(p_bayes.keys()) | set(p_mc.keys())
    ensemble = {}
    for cinquina in tutte_cinquine:
        p1 = p_comb.get(cinquina, 0)
        p2 = p_bayes.get(cinquina, 0)
        p3 = p_mc.get(cinquina, 0)
        ensemble[cinquina] = (p1 + p2 + p3) / 3  # Media semplice; modificare i pesi se necessario

    return ensemble

def salva_probabilita_su_file(nome_file, prob_dict, titolo="Probabilità"):
    """
    Salva le probabilità calcolate in un file di testo con il titolo specificato.
    """
    with open(nome_file, 'w', encoding='utf-8') as f:
        f.write(f"{titolo}\n")
        for n in sorted(prob_dict):
            f.write(f"{n:2d}: {prob_dict[n]:.8f}\n")

def stampa_top(prob_dict, top_n=15, titolo=""):
    """
    Stampa i primi top_n numeri in base alla probabilità.
    """
    numeri_ordinati = sorted(prob_dict.items(), key=lambda x: x[1], reverse=True)
    if titolo:
        print(f"\n{titolo}")
    top_15 = []
    for numero, prob in numeri_ordinati[:top_n]:
        print(f"  {numero}: {prob:.8f}")
        top_15.append(numero)
    return top_15

def main():
    # Ottenere timestamp
    timestamp = get_timestamp()

    # Paramento della linea di comando
    parser = argparse.ArgumentParser(
        description="Analisi dei numeri con tecniche Monte Carlo, combinatorie, Bayesiane ed Ensemble."
    )
    parser.add_argument("nome_file", type=str, help="Il nome del file contenente le estrazioni.")
    parser.add_argument("n_simulazioni", type=int, help="Numero di simulazioni Monte Carlo da eseguire.")
    parser.add_argument("--alpha", type=float, default=1, help="Parametro di smoothing per il modello Bayesiano (default: 1)")
    args = parser.parse_args()

    nome_file = args.nome_file
    n_simulazioni = args.n_simulazioni
    alpha = args.alpha

    # Leggere i dati dal file di input
    estrazioni = leggi_file(nome_file)
    if not estrazioni:
        print("Nessuna estrazione valida trovata nel file.")
        return

    # Calcolo delle probabilità con i metodi
    p_comb = normalizza_probabilita(calcola_probabilita_combinatoria(estrazioni))
    p_bayes = normalizza_probabilita(modello_bayesiano(estrazioni, alpha))
    p_mc = normalizza_probabilita(genera_numeri_aleatori(estrazioni, n_simulazioni))
    
    # Calcolo dell'ensemble
    p_ensemble = normalizza_probabilita(modello_ensemble(estrazioni, alpha, n_simulazioni))

    # Stampa e salva i risultati
    salva_probabilita_su_file(f"probabilita_combinatorio_{timestamp}.txt", p_comb, "Metodo Combinatorio")
    salva_probabilita_su_file(f"probabilita_bayesiano_{timestamp}.txt", p_bayes, "Metodo Bayesiano")
    salva_probabilita_su_file(f"probabilita_montecarlo_{timestamp}.txt", p_mc, "Metodo Monte Carlo")
    salva_probabilita_su_file(f"probabilita_ensemble_{timestamp}.txt", p_ensemble, "Metodo Ensemble")

    # Top 15 risultati
    top_15_finali = stampa_top(p_ensemble, 15, "Top 15 Numeri Probabili (Ensemble)")
    
    with open(f"top15_ensemble_storico_{timestamp}.txt", 'w', encoding='utf-8') as f:
        f.write("Top 15 Numeri Ordinati:\n")
        f.write(" ".join(str(n) for n in top_15_finali) + "\n")

if __name__ == "__main__":
    main()

