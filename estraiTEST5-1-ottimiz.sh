#
#
import random
from collections import Counter
import os
import argparse
import math
import numpy as np


def leggi_file(nome_file):
    """
    Legge il file di input e restituisce una lista di tuple a 7 numeri.
    """
    settine = []
    if not os.path.exists(nome_file):
        print(f"Errore: il file '{nome_file}' non esiste.")
        return settine

    with open(nome_file, 'r', encoding='utf-8') as file:
        for linea in file:
            dati = linea.strip().split()
            try:
                numeri = list(map(int, dati[1:]))  # Ignora la data nella prima colonna
                if len(numeri) == 15:
                    settine.append(tuple(numeri))
                else:
                    print(f"Linea ignorata per formato non valido: {linea.strip()}")
            except ValueError:
                print(f"Errore di conversione nei numeri: {linea.strip()}")
    return settine


def calcola_probabilità_combinatoria(settine):
    """
    Calcola le probabilità combinatorie per ogni settina osservata.
    """
    tutti_numeri = [numero for settina in settine for numero in settina]
    spazio_probabilistico = Counter(tutti_numeri)

    # Calcola la probabilità di ogni numero
    totale = sum(spazio_probabilistico.values())
    probabilità_numeri = {num: spazio_probabilistico[num] / totale for num in spazio_probabilistico}

    # Calcola la probabilità combinatoria di ciascuna settina
    probabilità_settine = {}
    for settina in settine:
        probabilità = math.prod(probabilità_numeri[num] for num in settina)
        probabilità_settine[settina] = probabilità

    # Ordina le settine per probabilità discendente
    settine_ordinate = sorted(probabilità_settine.items(), key=lambda x: x[1], reverse=True)
    return settine_ordinate


def modello_bayesiano(settine, alpha):
    """
    Applica un modello Bayesiano per stimare le probabilità delle settine.
    """
    tutti_numeri = [numero for settina in settine for numero in settina]
    spazio_probabilistico = Counter(tutti_numeri)

    # Calcola le probabilità a priori
    totale = sum(spazio_probabilistico.values())
    probabilità_posteriori = {}
    for num in spazio_probabilistico:
        probabilità_posteriori[num] = (spazio_probabilistico[num] + alpha) / (totale + alpha * len(spazio_probabilistico))

    # Calcola la probabilità di ciascuna settina basata sul modello Bayesiano
    probabilità_settine = {}
    for settina in settine:
        probabilità = math.prod(probabilità_posteriori[num] for num in settina)
        probabilità_settine[settina] = probabilità

    # Ordina le settine per probabilità discendente
    settine_ordinate = sorted(probabilità_settine.items(), key=lambda x: x[1], reverse=True)
    return settine_ordinate


def genera_numeri_aleatori(settine, n_simulazioni=100000):
    """
    Genera simulazioni di estrazioni casuali per calcolare le probabilità
    di combinazioni basate su Monte Carlo.
    """
    conteggi = Counter()

    # Estrai tutti i numeri unici dal dataset
    tutti_numeri = [numero for settina in settine for numero in settina]
    spazio_probabilistico = Counter(tutti_numeri)

    # Normalizza lo spazio probabilistico
    totale = sum(spazio_probabilistico.values())
    probabilità = {num: spazio_probabilistico[num] / totale for num in spazio_probabilistico}

    # Simula l'estrazione
    for _ in range(n_simulazioni):
        estrazione = tuple(sorted(random.choices(list(probabilità.keys()), weights=probabilità.values(), k=15)))
        conteggi[estrazione] += 1

    return conteggi


def stampa_top_settine_monte_carlo(conteggi, n_simulazioni, top_n=1):
    """
    Stampa le top N settine più probabili calcolate tramite Monte Carlo.
    """
    # Calcola le probabilità stimate
    probabilità_stimate = {
        tuple(map(int, settina)): conteggio / n_simulazioni
        for settina, conteggio in conteggi.items()
    }

    # Ordina le settine in base alla probabilità stimata
    settine_ordinate = sorted(probabilità_stimate.items(), key=lambda x: x[1], reverse=True)

    # Stampa le top N settine
    #print(f"\nLa {top_n} cinquina più probabile secondo il metodo Monte Carlo è:")
    for settina, prob in settine_ordinate[:top_n]:
        print(f"La cinquina più probabile secondo il metodo Monte Carlo è:  {settina}: {prob:.5f}")


def main():
    # Configura il parser per gli argomenti da riga di comando
    parser = argparse.ArgumentParser(description="Analisi di settine con tecniche Monte Carlo, combinatorie e Bayesiane.")
    parser.add_argument("nome_file", type=str, help="Il nome del file contenente le settine.")
    parser.add_argument("n_simulazioni", type=int, help="Il numero di simulazioni Monte Carlo da eseguire.")
    parser.add_argument("--alpha", type=float, default=1, help="Parametro di smoothing per il modello Bayesiano (default: 1)")

    # Analizza gli argomenti
    args = parser.parse_args()
    nome_file = args.nome_file
    n_simulazioni = args.n_simulazioni
    alpha = args.alpha

    # Leggi il file
    settine = leggi_file(nome_file)

    if not settine:
        print("Nessuna settina valida trovata nel file.")
        return

    # Probabilità combinatoria
    print("\nCalcolo delle probabilità combinatorie...")
    settine_combinatorie = calcola_probabilità_combinatoria(settine)
    #print(f"La 1 cinquina più probabile secondo la probabilità combinatoria è:")
    for settina, prob in settine_combinatorie[:1]:
        print(f"La cinquina più probabile secondo la probabilità combinatoria è:   {settina}: {prob:.10f}")

    # Modello Bayesiano
    print("\nCalcolo delle probabilità Bayesiane...")
    settine_bayesiane = modello_bayesiano(settine, alpha=alpha)
    #print(f"La 1 cinquina più probabile secondo il modello Bayesiano è:")
    for settina, prob in settine_bayesiane[:1]:
        print(f"La cinquina più probabile secondo il modello Bayesiano è:  {settina}: {prob:.10f}")

    # Simulazioni Monte Carlo
    print(f"\nInizio simulazioni Monte Carlo con {n_simulazioni} iterazioni...")
    conteggi = genera_numeri_aleatori(settine, n_simulazioni)

    # Stampa le top 5 settine più probabili
    stampa_top_settine_monte_carlo(conteggi, n_simulazioni, top_n=1)


if __name__ == "__main__":
    main()
