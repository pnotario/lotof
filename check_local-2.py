import time
import random

def random_delay(min_delay=1, max_delay=3):
    """Introduce un ritardo casuale per simulare il comportamento umano."""
    time.sleep(random.uniform(min_delay, max_delay))

def format_numbers_inplace(file_path):
    """Formatta i numeri nel file, aggiungendo uno zero iniziale ai numeri a una cifra."""
    try:
        with open(file_path, 'r', encoding='utf-8') as infile:
            lines = infile.readlines()
        
        with open(file_path, 'w', encoding='utf-8') as outfile:
            for line in lines:
                formatted_line = '\t'.join(f"{int(num):02}" for num in line.split())
                outfile.write(formatted_line + '\n')
    except FileNotFoundError:
        print(f"❌ Errore: Il file '{file_path}' non esiste.")

def recupera_numeri_estratti_concorso(concorso_numero):
    """Recupera i numeri estratti per un determinato concorso dal file './dat/dati.txt'."""
    try:
        with open('./dat/dati.txt', 'r', encoding='utf-8') as file:
            for line in file:
                # Splitta la linea e recupera il numero del concorso
                parts = line.split('\t')
                concorso = parts[0].strip()

                # Se il numero del concorso corrisponde, restituisci i numeri estratti
                if concorso == str(concorso_numero):
                    numeri_estratti = set(parts[2:])  # Numeri estratti sono nella terza colonna in avanti
                    return numeri_estratti
                
        print(f"⚠️ Concorso {concorso_numero} non trovato in './dat/dati.txt'.")
        return set()
    except FileNotFoundError:
        print("❌ Errore: Il file './dat/dati.txt' non esiste.")
        return set()

def confronta_numeri(giocati, estratti):
    """Confronta i numeri giocati con quelli estratti."""
    numeri_indovinati = giocati.intersection(estratti)
    return numeri_indovinati, len(numeri_indovinati)

def main():
    # Ricevi il numero del concorso come parametro
    import sys
    if len(sys.argv) != 2:
        print("❌ Usa: python3 check_local.py <numero_concorso | all>")
        return

    concorso_param = sys.argv[1]

    # Formatta il file puntata.txt prima di utilizzarlo
    file_puntata = './dat/puntata.txt'
    format_numbers_inplace(file_puntata)
    
    try:
        with open(file_puntata, 'r', encoding='utf-8') as f:
            righe = f.readlines()
    except FileNotFoundError:
        print("❌ File 'puntata.txt' non trovato.")
        return

    sommario = []

    if concorso_param == "all":
        # Se il parametro è "all", controlla tutti i concorsi nel file './dat/dati.txt'
        try:
            with open('./dat/dati.txt', 'r', encoding='utf-8') as file:
                for line in file:
                    parts = line.split('\t')
                    concorso_numero = parts[0].strip()
                    
                    # Recupera i numeri estratti per il concorso corrente
                    print(f"🔄 Recupero dei numeri estratti per il concorso {concorso_numero}...")
                    numeri_estratti = recupera_numeri_estratti_concorso(concorso_numero)

                    if numeri_estratti:
                        numeri_estratti_sorted = sorted(numeri_estratti)
                        print(f"\nNumeri estratti per il concorso {concorso_numero}: {', '.join(numeri_estratti_sorted)}\n")
                        print("="*50)

                        # Confronto tra i numeri giocati e quelli estratti per ogni riga
                        for idx, riga in enumerate(righe, start=1):
                            numeri_giocati = set(riga.strip().replace("\t", " ").split())
                            numeri_giocati_sorted = sorted(numeri_giocati)

                            numeri_indovinati, tot_indovinati = confronta_numeri(numeri_giocati, numeri_estratti)
                            numeri_indovinati_sorted = sorted(numeri_indovinati)

                            print(f"📝 Risultati per la riga {idx}:")
                            print(f"  Numeri giocati: {', '.join(numeri_giocati_sorted)}")
                            print(f"  Numeri indovinati: {', '.join(numeri_indovinati_sorted)}")
                            print(f"\033[1m  Totale numeri indovinati: {tot_indovinati}\033[0m")
                            print("-"*50)

                            # Aggiungi il risultato al sommario, solo se indovinati 11, 12, 13, 14 o 15 numeri
                            if tot_indovinati in [11, 12, 13, 14, 15]:
                                sommario.append((concorso_numero, idx, tot_indovinati))

        except FileNotFoundError:
            print("❌ Errore: Il file './dat/dati.txt' non esiste.")
            return
    else:
        # Se il parametro è un numero di concorso, controlla solo quel concorso
        print(f"🔄 Recupero dei numeri estratti per il concorso {concorso_param}...")
        numeri_estratti = recupera_numeri_estratti_concorso(concorso_param)

        if not numeri_estratti:
            print("⚠️ Non sono riuscito a recuperare i numeri estratti.")
            return

        numeri_estratti_sorted = sorted(numeri_estratti)
        print(f"\nNumeri estratti per il concorso {concorso_param}: {', '.join(numeri_estratti_sorted)}\n")
        print("="*50)

        # Confronto tra i numeri giocati e quelli estratti per ogni riga
        for idx, riga in enumerate(righe, start=1):
            numeri_giocati = set(riga.strip().replace("\t", " ").split())
            numeri_giocati_sorted = sorted(numeri_giocati)

            numeri_indovinati, tot_indovinati = confronta_numeri(numeri_giocati, numeri_estratti)
            numeri_indovinati_sorted = sorted(numeri_indovinati)

            print(f"📝 Risultati per la riga {idx}:")
            print(f"  Numeri giocati: {', '.join(numeri_giocati_sorted)}")
            print(f"  Numeri indovinati: {', '.join(numeri_indovinati_sorted)}")
            print(f"\033[1m  Totale numeri indovinati: {tot_indovinati}\033[0m")
            print("-"*50)

            # Aggiungi il risultato al sommario, solo se indovinati 11, 12, 13, 14 o 15 numeri
            if tot_indovinati in [11, 12, 13, 14, 15]:
                sommario.append((concorso_param, idx, tot_indovinati))

    # Ordinamento del sommario in ordine decrescente per numero di numeri indovinati
    sommario.sort(key=lambda x: x[2], reverse=True)

    # Visualizzazione del sommario
    print("\n📊 Sommario dei risultati (ordinato per numeri indovinati):")
    for concorso_numero, riga_idx, tot_indovinati in sommario:
        if tot_indovinati in [11, 12, 13, 14]:
            print(f"\033[1mConcorso {concorso_numero}, Riga {riga_idx}: {tot_indovinati} numeri indovinati\033[0m")  # Bold
        elif tot_indovinati == 15:
            print(f"\033[1;5mConcorso {concorso_numero}, Riga {riga_idx}: {tot_indovinati} numeri indovinati\033[0m")  # Bold + Blink
        else:
            print(f"Concorso {concorso_numero}, Riga {riga_idx}: {tot_indovinati} numeri indovinati")

if __name__ == "__main__":
    main()

