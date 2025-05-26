import random
from collections import Counter
import os
import argparse

def leggi_file(nome_file):
    estrazioni = []
    if not os.path.exists(nome_file):
        print(f"Errore: il file '{nome_file}' non esiste.")
        return estrazioni

    with open(nome_file, 'r', encoding='utf-8') as file:
        for linea in file:
            dati = linea.strip().split()
            if len(dati) < 17:
                continue
            try:
                numeri = list(map(int, dati[2:17]))
                # Consideriamo solo numeri da 1 a 25
                numeri = [n for n in numeri if 1 <= n <= 25]
                if len(numeri) == 15:
                    estrazioni.append(numeri)
            except ValueError:
                continue
    return estrazioni

def calcola_probabilita_combinatoria(estrazioni):
    tutti_numeri = [num for estrazione in estrazioni for num in estrazione]
    totale = len(tutti_numeri)
    conteggio = Counter(tutti_numeri)
    return {n: conteggio.get(n, 0) / totale for n in range(1, 26)}

def modello_bayesiano(estrazioni, alpha=1):
    tutti_numeri = [num for estrazione in estrazioni for num in estrazione]
    conteggio = Counter(tutti_numeri)
    totale = sum(conteggio.values())
    k = 25  # numeri da 1 a 25
    return {n: (conteggio.get(n, 0) + alpha) / (totale + alpha * k) for n in range(1, 26)}

def monte_carlo(estrazioni, n_simulazioni=100000):
    # Costruisce la distribuzione empirica da estrazioni reali
    tutti_numeri = [num for estrazione in estrazioni for num in estrazione]
    conteggio = Counter(tutti_numeri)
    totale = sum(conteggio.values())
    pesi = [conteggio.get(n, 0) / totale for n in range(1, 26)]

    risultati = Counter()
    for _ in range(n_simulazioni):
        campione = random.choices(range(1, 26), weights=pesi, k=15)
        risultati.update(campione)

    totale_sim = n_simulazioni * 15
    return {n: risultati.get(n, 0) / totale_sim for n in range(1, 26)}

def stampa_top_15(prob_dict, titolo=""):
    # Prende i 15 con la probabilità più alta, poi li ordina numericamente
    top_15 = sorted(prob_dict.items(), key=lambda x: x[1], reverse=True)[:15]
    numeri_top = sorted([num for num, _ in top_15])
    print(f"\n{titolo}")
    print("Numeri più probabili (ordinati):", numeri_top)

def main():
    parser = argparse.ArgumentParser(description="Analisi probabilistica basata su estrazioni reali.")
    parser.add_argument("file", type=str, help="File contenente estrazioni (15 numeri da 1 a 25 per riga)")
    parser.add_argument("--alpha", type=float, default=1, help="Parametro di smoothing per il modello Bayesiano")
    parser.add_argument("--simulazioni", type=int, default=100000, help="Numero di simulazioni per Monte Carlo")
    args = parser.parse_args()

    estrazioni = leggi_file(args.file)
    if not estrazioni:
        print("Nessuna estrazione valida trovata.")
        return

    # Calcolo probabilità
    prob_comb = calcola_probabilita_combinatoria(estrazioni)
    prob_bayes = modello_bayesiano(estrazioni, args.alpha)
    prob_mc = monte_carlo(estrazioni, args.simulazioni)

    # Stampa risultati
    stampa_top_15(prob_comb, "Metodo Combinatorio")
    stampa_top_15(prob_bayes, "Metodo Bayesiano")
    stampa_top_15(prob_mc, "Metodo Monte Carlo")

if __name__ == "__main__":
    main()
