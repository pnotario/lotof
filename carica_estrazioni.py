import mysql.connector
from mysql.connector import errorcode
import datetime

def leggi_file(nome_file):
    estrazioni = []
    with open(nome_file, 'r', encoding='utf-8') as f:
        for linea in f:
            dati = linea.strip().split()
            if len(dati) != 17:
                print(f"⚠️ Riga ignorata (formato non valido): {linea.strip()}")
                continue
            try:
                # dati[0] = numero concorso (ignoriamo)
                data_str = dati[1]
                data = datetime.datetime.strptime(data_str, '%d/%m/%Y').date()
                numeri = list(map(int, dati[2:]))
                if len(numeri) != 15:
                    print(f"⚠️ Riga ignorata (numeri non validi): {linea.strip()}")
                    continue
                estrazioni.append((data, numeri))
            except Exception as e:
                print(f"⚠️ Riga ignorata (errore parsing): {linea.strip()} - {e}")
    return estrazioni

def carica_estrazioni(conn, estrazioni):
    inserite = 0
    ignorate = 0
    errori = 0
    cursor = conn.cursor()

    for data, numeri in estrazioni:
        try:
            cursor.execute("""
                INSERT IGNORE INTO estrazioni_reali 
                (data, n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14, n15)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (data, *numeri))
            if cursor.rowcount == 1:
                inserite += 1
            else:
                ignorate += 1
        except mysql.connector.Error as err:
            print(f"❌ Errore inserimento riga: {err}")
            errori += 1

    conn.commit()
    cursor.close()
    print("✅ Caricamento completato.")
    print(f"✔️ Inserite: {inserite}")
    print(f"⏭️ Ignorate (già presenti): {ignorate}")
    print(f"⚠️ Righe con errore: {errori}")

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Carica estrazioni reali nel DB MariaDB.")
    parser.add_argument("nome_file", help="File con estrazioni reali")
    parser.add_argument("--host", default="localhost")
    parser.add_argument("--user", default="tuo_utente")
    parser.add_argument("--password", default="tua_password")
    parser.add_argument("--database", default="lotterie")
    args = parser.parse_args()

    try:
        conn = mysql.connector.connect(
            host=args.host,
            user=args.user,
            password=args.password,
            database=args.database
        )
    except mysql.connector.Error as err:
        print(f"Errore nella connessione al DB: {err}")
        return

    estrazioni = leggi_file(args.nome_file)
    if not estrazioni:
        print("Nessuna estrazione valida trovata nel file.")
        return

    carica_estrazioni(conn, estrazioni)
    conn.close()

if __name__ == "__main__":
    main()

