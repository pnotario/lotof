import random
from collections import Counter
import os
import argparse
import math

def genera_serie_casuale():
    return random.sample(range(1, 26), 25)

def calcola_probabilita_combinatoria(numeri):
    conteggio = Counter(numeri)
    totale = sum(conteggio.values())
    return {n: conteggio[n] / totale for n in range(1, 26)}

def modello_bayesiano(numeri, alpha):
    conteggio = Counter(numeri)
    totale = sum(conteggio.values())
    k = 25
    return {n: (conteggio.get(n, 0) + alpha) / (totale + alpha * k) for n in range(1, 26)}

def genera_probabilita_monte_carlo(numeri, n_simulazioni):
    conteggio_input = Counter(numeri)
    totale = sum(conteggio_input.values())
    probabilita = {n: conteggio_input.get(n, 0) / totale for n in range(1, 26)}

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

def metodo_ensemble(p1, p2, p3):
    ensemble = {}
    for n in range(1, 26):
        ensemble[n] = (p1.get(n, 0) + p2.get(n, 0) + p3.get(n, 0)) / 3
    return normalizza_probabilita(ensemble)

def leggi_estrazioni(nome_file):
    estrazioni = []
    if not os.path.exists(nome_file):
        print(f"Errore: file '{nome_file}' non trovato.")
        return estrazioni

    with open(nome_file, 'r', encoding='utf-8') as file:
        for linea in file:
            dati = linea.strip().split()
            try:
                numeri = list(map(int, dati[2:]))
                if len(numeri) == 15:
                    estrazioni.append(numeri)
            except ValueError:
                continue
    return estrazioni

def calcola_frequenza_su_estrazioni(ensemble_prob, estrazioni):
    conteggio = Counter()
    for estrazione in estrazioni:
        for numero in estrazione:
            conteggio[numero] += 1

    totale = sum(conteggio.values())
    frequenze = {
        n: (conteggio[n] / totale if totale > 0 else 0) * ensemble_prob[n]
        for n in range(1, 26)
    }
    return frequenze

def stampa_top_15(prob_dict, titolo="Top 15 Numeri"):
    top_15 = sorted(prob_dict.items(), key=lambda x: x[1], reverse=True)[:15]
    ordinati = sorted([num for num, _ in top_15])
    print(f"\n{titolo}:")
    print("Numeri selezionati:", ordinati)
    return ordinati

def stampa_probabilita(title, prob_dict):
    print(f"\n📊 Probabilità - {title}")
    for n in sorted(prob_dict.keys()):
        print(f"  {n:2d}: {prob_dict[n]:.6f}")

def main():
    parser = argparse.ArgumentParser(description="Calcolo probabilità su base casuale + estrazioni storiche.")
    parser.add_argument("nome_file", type=str, help="File con le estrazioni da 15 numeri")
    parser.add_argument("n_simulazioni", type=int, help="Numero di simulazioni per Monte Carlo")
    parser.add_argument("--alpha", type=float, default=1.0, help="Parametro smoothing Bayes (default 1.0)")
    args = parser.parse_args()

    # 1. Genera numeri casuali da 1 a 25
    numeri_casuali = genera_serie_casuale()

    # 2. Calcolo probabilità
    p_comb = normalizza_probabilita(calcola_probabilita_combinatoria(numeri_casuali))
    stampa_probabilita("Metodo Combinatorio", p_comb)

    p_bayes = normalizza_probabilita(modello_bayesiano(numeri_casuali, args.alpha))
    stampa_probabilita("Metodo Bayesiano", p_bayes)

    p_mc = normalizza_probabilita(genera_probabilita_monte_carlo(numeri_casuali, args.n_simulazioni))
    stampa_probabilita("Metodo Monte Carlo", p_mc)

    # 3. Metodo Ensemble
    p_ensemble = metodo_ensemble(p_comb, p_bayes, p_mc)
    stampa_probabilita("Metodo Ensemble", p_ensemble)

    # 4. Leggi estrazioni dal file
    estrazioni = leggi_estrazioni(args.nome_file)
    if not estrazioni:
        print("Nessuna estrazione valida trovata.")
        return

    # 5. Calcola frequenze finali pesate su estrazioni
    frequenze_finali = calcola_frequenza_su_estrazioni(p_ensemble, estrazioni)

    # 6. Mostra i top 15
    stampa_top_15(frequenze_finali, "Top 15 Numeri Probabili (Ensemble + Storico)")

if __name__ == "__main__":
    main()

