#
#
import random
from collections import Counter
import os
import argparse
import math
import numpy as np
import xgboost as xgb


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

    totale = sum(spazio_probabilistico.values())
    probabilità_numeri = {num: spazio_probabilistico[num] / totale for num in spazio_probabilistico}

    probabilità_settine = {}
    for settina in settine:
        probabilità = math.prod(probabilità_numeri[num] for num in settina)
        probabilità_settine[settina] = probabilità

    settine_ordinate = sorted(probabilità_settine.items(), key=lambda x: x[1], reverse=True)
    return settine_ordinate


def modello_bayesiano(settine, alpha):
    """
    Applica un modello Bayesiano per stimare le probabilità delle settine.
    """
    tutti_numeri = [numero for settina in settine for numero in settina]
    spazio_probabilistico = Counter(tutti_numeri)

    totale = sum(spazio_probabilistico.values())
    probabilità_posteriori = {}
    for num in spazio_probabilistico:
        probabilità_posteriori[num] = (spazio_probabilistico[num] + alpha) / (totale + alpha * len(spazio_probabilistico))

    probabilità_settine = {}
    for settina in settine:
        probabilità = math.prod(probabilità_posteriori[num] for num in settina)
        probabilità_settine[settina] = probabilità

    settine_ordinate = sorted(probabilità_settine.items(), key=lambda x: x[1], reverse=True)
    return settine_ordinate


def genera_numeri_aleatori(settine, n_simulazioni=100000):
    """
    Genera simulazioni di estrazioni casuali per calcolare le probabilità
    di combinazioni basate su Monte Carlo senza numeri ripetuti.
    """
    conteggi = Counter()

    tutti_numeri = [numero for settina in settine for numero in settina]
    spazio_probabilistico = Counter(tutti_numeri)

    totale = sum(spazio_probabilistico.values())
    probabilità = {num: spazio_probabilistico[num] / totale for num in spazio_probabilistico}
    numeri_possibili = list(probabilità.keys())
    pesi = list(probabilità.values())

    for _ in range(n_simulazioni):
        estrazione = tuple(sorted(random.choices(numeri_possibili, weights=pesi, k=15)))
        # elimina ripetizioni se presenti (random.choices può scegliere con ripetizioni)
        # per estrazioni senza ripetizioni meglio usare random.sample con pesi approssimati:
        # ma random.sample non supporta pesi nativamente, si usa np.random.choice con replace=False
        estrazione = tuple(sorted(np.random.choice(numeri_possibili, size=15, replace=False, p=pesi/np.sum(pesi))))
        conteggi[estrazione] += 1

    return conteggi


def stampa_top_settine_monte_carlo(conteggi, n_simulazioni, top_n=1):
    probabilità_stimate = {
        tuple(map(int, settina)): conteggio / n_simulazioni
        for settina, conteggio in conteggi.items()
    }

    settine_ordinate = sorted(probabilità_stimate.items(), key=lambda x: x[1], reverse=True)

    for settina, prob in settine_ordinate[:top_n]:
        print(f"Combinazione più probabile:  {settina}: {prob:.5f}")


def estrazione_markov_chain(settine):
    """
    Semplice modello Markov Chain per estrarre numeri.
    Frequenze condizionate tra numeri consecutivi nelle settine.
    """
    transitions = {}
    counts = {}

    for settina in settine:
        for i in range(len(settina) - 1):
            curr_num = settina[i]
            next_num = settina[i + 1]
            if curr_num not in transitions:
                transitions[curr_num] = Counter()
                counts[curr_num] = 0
            transitions[curr_num][next_num] += 1
            counts[curr_num] += 1

    # Probabilità di transizione
    for curr_num in transitions:
        total = counts[curr_num]
        for next_num in transitions[curr_num]:
            transitions[curr_num][next_num] /= total

    # Estrazione
    numeri_possibili = list(set(num for settina in settine for num in settina))
    start = random.choice(numeri_possibili)
    risultato = [start]
    while len(risultato) < 15:
        current = risultato[-1]
        next_nums = list(transitions.get(current, {}).keys())
        next_probs = list(transitions.get(current, {}).values())
        if not next_nums:
            # se non esiste transizione, scegli random da tutti i numeri possibili senza duplicati
            remaining = [n for n in numeri_possibili if n not in risultato]
            if not remaining:
                break
            risultato.append(random.choice(remaining))
        else:
            next_num = random.choices(next_nums, weights=next_probs)[0]
            if next_num not in risultato:
                risultato.append(next_num)
            else:
                # se ripetuto, scegli random da remaining
                remaining = [n for n in numeri_possibili if n not in risultato]
                if not remaining:
                    break
                risultato.append(random.choice(remaining))

    return tuple(sorted(risultato))


def estrazione_regressione_logistica(settine):
    """
    Esempio semplificato di estrazione con regressione logistica.
    Usa feature base e normalizza valori.
    """
    from sklearn.linear_model import LogisticRegression

    freq_n = Counter(numero for settina in settine for numero in settina)

    X = []
    y = []

    # Crea dataset: ogni numero nelle settine è un campione positivo
    for settina in settine:
        for num in settina:
            features = [num, num % 10, num // 10, freq_n[num]]
            X.append(features)
            y.append(1)  # Segnale positivo

    # Per semplicità, aggiungiamo campioni negativi (numeri casuali non nelle settine)
    numeri_possibili = set(range(1, 91))
    numeri_presenti = set(freq_n.keys())
    numeri_assenti = list(numeri_possibili - numeri_presenti)

    for _ in range(len(X)):
        num_neg = random.choice(numeri_assenti)
        features = [num_neg, num_neg % 10, num_neg // 10, 0]
        X.append(features)
        y.append(0)

    X = np.array(X)
    y = np.array(y)

    model = LogisticRegression(max_iter=1000)
    model.fit(X, y)

    # Predici probabilità su tutti i numeri da 1 a 90
    X_test = np.array([[n, n % 10, n // 10, freq_n.get(n, 0)] for n in range(1, 91)])
    prob_pred = model.predict_proba(X_test)[:, 1]

    # Seleziona i 15 numeri con probabilità più alta
    top_indices = prob_pred.argsort()[-15:][::-1]
    estratti = tuple(sorted([i + 1 for i in top_indices]))
    return estratti


def estrazione_random_forest(settine):
    """
    Estrazione con Random Forest.
    """
    from sklearn.ensemble import RandomForestClassifier

    freq_n = Counter(numero for settina in settine for numero in settina)

    X = []
    y = []

    for settina in settine:
        for num in settina:
            features = [num, num % 10, num // 10, freq_n[num]]
            X.append(features)
            y.append(1)

    numeri_possibili = set(range(1, 91))
    numeri_presenti = set(freq_n.keys())
    numeri_assenti = list(numeri_possibili - numeri_presenti)

    for _ in range(len(X)):
        num_neg = random.choice(numeri_assenti)
        features = [num_neg, num_neg % 10, num_neg // 10, 0]
        X.append(features)
        y.append(0)

    X = np.array(X)
    y = np.array(y)

    clf = RandomForestClassifier()
    clf.fit(X, y)

    X_test = np.array([[n, n % 10, n // 10, freq_n.get(n, 0)] for n in range(1, 91)])
    prob_pred = clf.predict_proba(X_test)[:, 1]

    top_indices = prob_pred.argsort()[-15:][::-1]
    estratti = tuple(sorted([i + 1 for i in top_indices]))
    return estratti


def estrazione_xgboost(settine):
    """
    Estrazione con XGBoost senza warning su use_label_encoder.
    """
    freq_n = Counter(numero for settina in settine for numero in settina)

    X = []
    y = []

    for settina in settine:
        for num in settina:
            features = [num, num % 10, num // 10, freq_n[num]]
            X.append(features)
            y.append(1)

    numeri_possibili = set(range(1, 91))
    numeri_presenti = set(freq_n.keys())
    numeri_assenti = list(numeri_possibili - numeri_presenti)

    for _ in range(len(X)):
        num_neg = random.choice(numeri_assenti)
        features = [num_neg, num_neg % 10, num_neg // 10, 0]
        X.append(features)
        y.append(0)

    X = np.array(X)
    y = np.array(y)

    clf = xgb.XGBClassifier(eval_metric="logloss")
    clf.fit(X, y)

    X_test = np.array([[n, n % 10, n // 10, freq_n.get(n, 0)] for n in range(1, 91)])
    prob_pred = clf.predict_proba(X_test)[:, 1]

    top_indices = prob_pred.argsort()[-15:][::-1]
    estratti = tuple(sorted([i + 1 for i in top_indices]))
    return estratti


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

    print("\nProbabilità combinatorie:")
    settine_combinatorie = calcola_probabilità_combinatoria(settine)
    for settina, prob in settine_combinatorie[:1]:
        print(f"Combinazione più probabile: {settina} - {prob:.10f}")

    print("\nProbabilità Bayesiane:")
    settine_bayesiane = modello_bayesiano(settine, alpha=alpha)
    for settina, prob in settine_bayesiane[:1]:
        print(f"Combinazione più probabile: {settina} - {prob:.10f}")

    print(f"\nSimulazione Monte Carlo ({n_simulazioni} iterazioni):")
    conteggi = genera_numeri_aleatori(settine, n_simulazioni)
    stampa_top_settine_monte_carlo(conteggi, n_simulazioni, top_n=1)

    print("\nEstrazione con Markov Chain:")
    estratto_markov = estrazione_markov_chain(settine)
    print(f"Combinazione più probabile: {estratto_markov} - {prob:.10f}")

    print("\nEstrazione con Regressione Logistica:")
    estratto_logistico = estrazione_regressione_logistica(settine)
    print(f"Combinazione più probabile: {estratto_logistico} - {prob:.10f}")

    print("\nEstrazione con Random Forest:")
    estratto_rf = estrazione_random_forest(settine)
    print(f"Combinazione più probabile: {estratto_rf} - {prob:.10f}")

    print("\nEstrazione con XGBoost:")
    estratto_xgb = estrazione_xgboost(settine)
    print(f"Combinazione più probabile: {estratto_xgb} - {prob:.10f}")


if __name__ == "__main__":
    main()



