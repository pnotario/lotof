import random
from collections import Counter
import os
import argparse
import math


def leggi_file(nome_file):
    settine = []
    if not os.path.exists(nome_file):
        print(f"Errore: il file '{nome_file}' non esiste.")
        return settine

    with open(nome_file, 'r', encoding='utf-8') as file:
        for linea in file:
            dati = linea.strip().split()
            try:
                numeri = list(map(int, dati[1:]))
                if len(numeri) == 15:
                    settine.append(tuple(numeri))
                else:
                    print(f"Linea ignorata per formato non valido: {linea.strip()}")
            except ValueError:
                print(f"Errore di conversione nei numeri: {linea.strip()}")
    return settine


def calcola_probabilità_combinatoria(settine):
    tutti_numeri = [numero for settina in settine for numero in settina]
    spazio_probabilistico = Counter(tutti_numeri)

    totale = sum(spazio_probabilistico.values())
    probabilità_numeri = {num: spazio_probabilistico[num] / totale for num in spazio_probabilistico}

    probabilità_settine = {}
    for settina in settine:
        probabilità = math.prod(probabilità_numeri[num] for num in settina)
        probabilità_settine[settina] = probabilità

    settine_ordinate = sorted(probabilità_settine.items(), key=lambda x: x[1], reverse=True)
    return settine_ordinate


def modello_bayesiano(settine, alpha):
    tutti_numeri = [numero for settina in settine for numero in settina]
    spazio_probabilistico = Counter(tutti_numeri)

    totale = sum(spazio_probabilistico.values())
    probabilità_posteriori = {
        num: (spazio_probabilistico[num] + alpha) / (totale + alpha * len(spazio_probabilistico))
        for num in spazio_probabilistico
    }

    probabilità_settine = {}
    for settina in settine:
        probabilità = math.prod(probabilità_posteriori[num] for num in settina)
        probabilità_settine[settina] = probabilità

    settine_ordinate = sorted(probabilità_settine.items(), key=lambda x: x[1], reverse=True)
    return settine_ordinate


def genera_numeri_aleatori(settine, n_simulazioni=100000):
    conteggi = Counter()
    tutti_numeri = list(set(numero for settina in settine for numero in settina))

    if len(tutti_numeri) < 15:
        print("Errore: non ci sono abbastanza numeri unici per generare combinazioni di 15 numeri senza ripetizioni.")
        return conteggi

    for _ in range(n_simulazioni):
        estrazione = tuple(sorted(random.sample(tutti_numeri, 15)))
        conteggi[estrazione] += 1

    return conteggi


def stampa_top_settine_monte_carlo(conteggi, n_simulazioni, top_n=1):
    probabilità_stimate = {
        settina: conteggio / n_simulazioni
        for settina, conteggio in conteggi.items()
    }

    settine_ordinate = sorted(probabilità_stimate.items(), key=lambda x: x[1], reverse=True)

    for settina, prob in settine_ordinate[:top_n]:
        settina_ordinata = tuple(sorted(settina))
        print(f"La cinquina più probabile secondo il metodo Monte Carlo è:  {settina_ordinata}: {prob:.5f}")


def main():
    parser = argparse.ArgumentParser(description="Analisi di settine con tecniche Monte Carlo, combinatorie e Bayesiane.")
    parser.add_argument("nome_file", type=str, help="Il nome del file contenente le settine.")
    parser.add_argument("n_simulazioni", type=int, help="Il numero di simulazioni Monte Carlo da eseguire.")
    parser.add_argument("--alpha", type=float, default=1, help="Parametro di smoothing per il modello Bayesiano (default: 1)")

    args = parser.parse_args()
    nome_file = args.nome_file
    n_simulazioni = args.n_simulazioni
    alpha = args.alpha

    settine = leggi_file(nome_file)

    if not settine:
        print("Nessuna settina valida trovata nel file.")
        return

    print("\nCalcolo delle probabilità combinatorie...")
    settine_combinatorie = calcola_probabilità_combinatoria(settine)
    for settina, prob in settine_combinatorie[:1]:
        print(f"La cinquina più probabile secondo la probabilità combinatoria è:   {tuple(sorted(settina))}: {prob:.10f}")

    print("\nCalcolo delle probabilità Bayesiane...")
    settine_bayesiane = modello_bayesiano(settine, alpha=alpha)
    for settina, prob in settine_bayesiane[:1]:
        print(f"La cinquina più probabile secondo il modello Bayesiano è:  {tuple(sorted(settina))}: {prob:.10f}")

    print(f"\nInizio simulazioni Monte Carlo con {n_simulazioni} iterazioni...")
    conteggi = genera_numeri_aleatori(settine, n_simulazioni)

    stampa_top_settine_monte_carlo(conteggi, n_simulazioni, top_n=1)


if __name__ == "__main__":
    main()

