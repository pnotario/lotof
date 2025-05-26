import random
from collections import Counter
import os
import argparse
import math
import numpy as np

try:
    import xgboost as xgb
    from sklearn.linear_model import LogisticRegression
    from sklearn.ensemble import RandomForestClassifier
except ImportError:
    print("Attenzione: alcune librerie ML non sono installate. Assicurati di installare xgboost, sklearn se usi i modelli ML.")

import mysql.connector

def connetti_db(host, user, password, database):
    try:
        conn = mysql.connector.connect(
            host=host,
            user=user,
            password=password,
            database=database
        )
        return conn
    except mysql.connector.Error as err:
        print(f"Errore nella connessione al DB: {err}")
        return None

def salva_estrazione(conn, tipo_modello, settina, probabilita):
    cur = conn.cursor()
    prob = float(probabilita)  # Converti a tipo float Python nativo
    cur.execute("""
        INSERT INTO estrazioni (modello, combinazione, probabilita)
        VALUES (%s, %s, %s)
    """, (tipo_modello, str(settina), prob))
    conn.commit()
    cur.close()

def leggi_file(nome_file):
    settine = []
    if not os.path.exists(nome_file):
        print(f"Errore: il file '{nome_file}' non esiste.")
        return settine

    with open(nome_file, 'r', encoding='utf-8') as file:
        for linea in file:
            dati = linea.strip().split()
            try:
                numeri = list(map(int, dati[1:16]))
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
        probabilità = math.prod(probabilità_numeri.get(num, 0) for num in settina)
        probabilità_settine[settina] = probabilità

    settine_ordinate = sorted(probabilità_settine.items(), key=lambda x: x[1], reverse=True)
    return settine_ordinate

def modello_bayesiano(settine, alpha):
    tutti_numeri = [numero for settina in settine for numero in settina]
    spazio_probabilistico = Counter(tutti_numeri)
    totale = sum(spazio_probabilistico.values())
    vocab_size = len(spazio_probabilistico)

    probabilità_posteriori = {num: (spazio_probabilistico[num] + alpha) / (totale + alpha * vocab_size) for num in spazio_probabilistico}

    probabilità_settine = {}
    for settina in settine:
        probabilità = math.prod(probabilità_posteriori.get(num, alpha / (totale + alpha * vocab_size)) for num in settina)
        probabilità_settine[settina] = probabilità

    settine_ordinate = sorted(probabilità_settine.items(), key=lambda x: x[1], reverse=True)
    return settine_ordinate

def genera_numeri_aleatori(settine, n_simulazioni=100000):
    conteggi = Counter()

    tutti_numeri = [numero for settina in settine for numero in settina]
    spazio_probabilistico = Counter(tutti_numeri)
    totale = sum(spazio_probabilistico.values())
    probabilità = np.array([spazio_probabilistico[num] / totale for num in range(1, 91)])
    numeri_possibili = np.arange(1, 91)

    for _ in range(n_simulazioni):
        estrazione = tuple(sorted(np.random.choice(numeri_possibili, size=15, replace=False, p=probabilità/probabilità.sum())))
        conteggi[estrazione] += 1

    return conteggi

def stampa_top_settine_monte_carlo(conteggi, n_simulazioni, top_n=1):
    probabilità_stimate = {settina: conteggio / n_simulazioni for settina, conteggio in conteggi.items()}
    settine_ordinate = sorted(probabilità_stimate.items(), key=lambda x: x[1], reverse=True)
    for settina, prob in settine_ordinate[:top_n]:
        print(f"Combinazione più probabile: {settina} - Probabilità media stimata: {prob:.10f}")

def estrazione_markov_chain(settine):
    transitions = {}
    counts = {}

    for settina in settine:
        for i in range(len(settina) - 1):
            curr_num = settina[i]
            next_num = settina[i + 1]
            transitions.setdefault(curr_num, Counter())[next_num] += 1
            counts[curr_num] = counts.get(curr_num, 0) + 1

    for curr_num in transitions:
        total = counts[curr_num]
        for next_num in transitions[curr_num]:
            transitions[curr_num][next_num] /= total

    numeri_possibili = list(set(num for settina in settine for num in settina))
    start = random.choice(numeri_possibili)
    risultato = [start]

    while len(risultato) < 15:
        current = risultato[-1]
        next_nums = list(transitions.get(current, {}).keys())
        next_probs = list(transitions.get(current, {}).values())
        if not next_nums:
            remaining = [n for n in numeri_possibili if n not in risultato]
            if not remaining:
                break
            risultato.append(random.choice(remaining))
        else:
            next_num = random.choices(next_nums, weights=next_probs)[0]
            if next_num not in risultato:
                risultato.append(next_num)
            else:
                remaining = [n for n in numeri_possibili if n not in risultato]
                if not remaining:
                    break
                risultato.append(random.choice(remaining))

    return tuple(sorted(risultato))

def estrazione_regressione_logistica(settine):
    freq_n = Counter(numero for settina in settine for numero in settina)
    X, y = [], []

    for settina in settine:
        for num in settina:
            X.append([num, num % 10, num // 10, freq_n[num]])
            y.append(1)

    numeri_possibili = set(range(1, 91))
    numeri_presenti = set(freq_n.keys())
    numeri_assenti = list(numeri_possibili - numeri_presenti)

    for _ in range(len(X)):
        num_neg = random.choice(numeri_assenti)
        X.append([num_neg, num_neg % 10, num_neg // 10, 0])
        y.append(0)

    X = np.array(X)
    y = np.array(y)

    model = LogisticRegression(max_iter=1000)
    model.fit(X, y)

    X_test = np.array([[n, n % 10, n // 10, freq_n.get(n, 0)] for n in range(1, 91)])
    prob_pred = model.predict_proba(X_test)[:, 1]

    top_indices = prob_pred.argsort()[-15:][::-1]
    estratti = tuple(sorted([i + 1 for i in top_indices]))
    return estratti, prob_pred[top_indices].mean()

def estrazione_random_forest(settine):
    freq_n = Counter(numero for settina in settine for numero in settina)
    X, y = [], []

    for settina in settine:
        for num in settina:
            X.append([num, num % 10, num // 10, freq_n[num]])
            y.append(1)

    numeri_possibili = set(range(1, 91))
    numeri_presenti = set(freq_n.keys())
    numeri_assenti = list(numeri_possibili - numeri_presenti)

    for _ in range(len(X)):
        num_neg = random.choice(numeri_assenti)
        X.append([num_neg, num_neg % 10, num_neg // 10, 0])
        y.append(0)

    X = np.array(X)
    y = np.array(y)

    clf = RandomForestClassifier()
    clf.fit(X, y)

    X_test = np.array([[n, n % 10, n // 10, freq_n.get(n, 0)] for n in range(1, 91)])
    prob_pred = clf.predict_proba(X_test)[:, 1]

    top_indices = prob_pred.argsort()[-15:][::-1]
    estratti = tuple(sorted([i + 1 for i in top_indices]))
    return estratti, prob_pred[top_indices].mean()

def estrazione_xgboost(settine):
    freq_n = Counter(numero for settina in settine for numero in settina)
    X, y = [], []

    for settina in settine:
        for num in settina:
            X.append([num, num % 10, num // 10, freq_n[num]])
            y.append(1)

    numeri_possibili = set(range(1, 91))
    numeri_presenti = set(freq_n.keys())
    numeri_assenti = list(numeri_possibili - numeri_presenti)

    for _ in range(len(X)):
        num_neg = random.choice(numeri_assenti)
        X.append([num_neg, num_neg % 10, num_neg // 10, 0])
        y.append(0)

    X = np.array(X)
    y = np.array(y)

    clf = xgb.XGBClassifier(eval_metric="logloss")
    clf.fit(X, y)

    X_test = np.array([[n, n % 10, n // 10, freq_n.get(n, 0)] for n in range(1, 91)])
    prob_pred = clf.predict_proba(X_test)[:, 1]

    top_indices = prob_pred.argsort()[-15:][::-1]
    estratti = tuple(sorted([i + 1 for i in top_indices]))
    return estratti, prob_pred[top_indices].mean()

def main():
    parser = argparse.ArgumentParser(description="Analisi di settine con tecniche Monte Carlo, combinatorie e Bayesiane.")
    parser.add_argument("nome_file", type=str, help="Il nome del file contenente le settine.")
    parser.add_argument("n_simulazioni", type=int, help="Il numero di simulazioni Monte Carlo da eseguire.")
    parser.add_argument("--alpha", type=float, default=1, help="Parametro di smoothing per il modello Bayesiano (default: 1)")
    parser.add_argument("--db_host", type=str, default="localhost", help="Host del database MariaDB")
    parser.add_argument("--db_user", type=str, required=True, help="Utente MariaDB")
    parser.add_argument("--db_password", type=str, required=True, help="Password MariaDB")
    parser.add_argument("--db_name", type=str, required=True, help="Nome database MariaDB")

    args = parser.parse_args()

    settine = leggi_file(args.nome_file)
    if not settine:
        print("Nessuna settina valida trovata, uscita.")
        return

    print("\nProbabilità combinatorie:")
    comb_prob = calcola_probabilità_combinatoria(settine)
    if comb_prob:
        print(f"Combinazione più probabile: {comb_prob[0][0]} - Probabilità media stimata: {comb_prob[0][1]:.10f}")

    print("\nProbabilità bayesiana:")
    bayes_prob = modello_bayesiano(settine, args.alpha)
    if bayes_prob:
        print(f"Combinazione più probabile: {bayes_prob[0][0]} - Probabilità media stimata: {bayes_prob[0][1]:.10f}")

    print("\nEstrazione Monte Carlo:")
    conteggi = genera_numeri_aleatori(settine, args.n_simulazioni)
    stampa_top_settine_monte_carlo(conteggi, args.n_simulazioni)

    print("\nEstrazione Markov Chain:")
    estratto_mc = estrazione_markov_chain(settine)
    print(f"Combinazione estratta: {estratto_mc}")

    print("\nEstrazione Regressione Logistica:")
    estratto_lr, prob_lr = estrazione_regressione_logistica(settine)
    print(f"Combinazione estratta: {estratto_lr} - Probabilità media stimata: {prob_lr:.10f}")

    print("\nEstrazione Random Forest:")
    estratto_rf, prob_rf = estrazione_random_forest(settine)
    print(f"Combinazione estratta: {estratto_rf} - Probabilità media stimata: {prob_rf:.10f}")

    print("\nEstrazione XGBoost:")
    estratto_xgb, prob_xgb = estrazione_xgboost(settine)
    print(f"Combinazione estratta: {estratto_xgb} - Probabilità media stimata: {prob_xgb:.10f}")

    # Connessione al DB MariaDB
    conn = connetti_db(args.db_host, args.db_user, args.db_password, args.db_name)
    if conn is None:
        print("Connessione al DB fallita, i risultati non saranno salvati.")
        return

    # Salvataggio estrazioni
    salva_estrazione(conn, "combinatoria", comb_prob[0][0], comb_prob[0][1])
    salva_estrazione(conn, "bayesiana", bayes_prob[0][0], bayes_prob[0][1])
    # Per Monte Carlo possiamo prendere la prima estrazione più probabile
    top_mc = sorted({k: v for k, v in conteggi.items()}.items(), key=lambda x: x[1], reverse=True)[0]
    salva_estrazione(conn, "monte_carlo", top_mc[0], top_mc[1]/args.n_simulazioni)
    salva_estrazione(conn, "markov_chain", estratto_mc, 0)  # Senza probabilità stimata
    salva_estrazione(conn, "logistic_regression", estratto_lr, prob_lr)
    salva_estrazione(conn, "random_forest", estratto_rf, prob_rf)
    salva_estrazione(conn, "xgboost", estratto_xgb, prob_xgb)

    conn.close()

if __name__ == "__main__":
    main()

