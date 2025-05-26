#!/usr/bin/env python3

import time
import random
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager

def random_delay(min_delay=1, max_delay=3):
    """Introduce un ritardo casuale per simulare il comportamento umano."""
    time.sleep(random.uniform(min_delay, max_delay))

def recupera_numeri_estratti_e_concorso():
    """Recupera i numeri estratti e il numero del concorso e la data dalla pagina Lotofácil."""
    chrome_options = Options()
    chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
    chrome_options.add_experimental_option("useAutomationExtension", False)
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("start-maximized")
    chrome_options.add_argument(
        "user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.51 Safari/537.36"
    )
    
    # Modalità headless rimossa per il debug, puoi riaggiungerla se necessario
    # chrome_options.add_argument("--headless=new")  # NECESSARIA per ambienti non grafici
    
    service = Service(ChromeDriverManager().install())
    driver = webdriver.Chrome(service=service, options=chrome_options)

    # Disabilita la property navigator.webdriver via CDP
    driver.execute_cdp_cmd(
        "Page.addScriptToEvaluateOnNewDocument",
        {"source": "Object.defineProperty(navigator, 'webdriver', {get: () => undefined})"},
    )

    driver.get("https://loterias.caixa.gov.br/Paginas/Lotofacil.aspx")
    random_delay()

    try:
        # Estrazione dei numeri estratti
        WebDriverWait(driver, 10).until(EC.presence_of_all_elements_located((By.CSS_SELECTOR, "ul.simple-container.lista-dezenas.lotofacil li")))
        num_elems = driver.find_elements(By.CSS_SELECTOR, "ul.simple-container.lista-dezenas.lotofacil li")
        numeri_estratti = {n.text.strip() for n in num_elems}

        # Estrazione del concorso e della data
        concorso_elem = driver.find_element(By.CSS_SELECTOR, "span.ng-binding")
        concorso_data = concorso_elem.text.strip()

        driver.quit()
        return numeri_estratti, concorso_data

    except Exception as e:
        print(f"❌ Errore durante il recupero dei numeri estratti: {e}")
        driver.quit()
        return set(), ""

def confronta_numeri(giocati, estratti):
    """Confronta i numeri giocati con quelli estratti."""
    numeri_indovinati = giocati.intersection(estratti)
    return numeri_indovinati, len(numeri_indovinati)

def main():
    # Recupera i numeri giocati dal file puntata.txt
    try:
        with open('./dat/puntata.txt', 'r', encoding='utf-8') as f:
            # Le righe del file contengono i numeri separati da spazi o tab
            righe = f.readlines()
    except FileNotFoundError:
        print("❌ File 'puntata.txt' non trovato.")
        return

    print("🔄 Recupero dei numeri estratti della Lotofácil...")
    numeri_estratti, concorso_data = recupera_numeri_estratti_e_concorso()

    if numeri_estratti:
        # Ordinamento dei numeri estratti
        numeri_estratti = sorted(numeri_estratti)
        print(f"\nConcorso: {concorso_data}")
        print(f"Numeri estratti: {', '.join(numeri_estratti)}\n")

        # Separatore
        print("="*50)

        # Itera su ogni riga del file puntata.txt
        for idx, riga in enumerate(righe, start=1):
            # Pulizia della riga e separazione dei numeri
            numeri_giocati = set(riga.strip().replace("\t", " ").split())  # Rimuoviamo tab e dividiamo per spazi
            numeri_giocati_sorted = sorted(numeri_giocati)

            # Confronto tra numeri giocati e numeri estratti
            numeri_indovinati, tot_indovinati = confronta_numeri(numeri_giocati, numeri_estratti)

            # Ordinamento dei numeri indovinati
            numeri_indovinati_sorted = sorted(numeri_indovinati)

            # Risultati più leggibili per questa riga
            print(f"📝 Risultati per la riga {idx}:")
            print(f"  Concorso: {concorso_data}")
            print(f"  Numeri giocati: {', '.join(numeri_giocati_sorted)}")
            print(f"  Numeri indovinati: {', '.join(numeri_indovinati_sorted)}")

            # Formattazione bold per il totale numeri indovinati
            print(f"\033[1m  Totale numeri indovinati: {tot_indovinati}\033[0m")  # ANSI escape code for bold
            print("-"*50)

            # Salvataggio dei risultati nel file
            with open("risultati.txt", "a", encoding="utf-8") as f:
                f.write(f"Risultati per la riga {idx}:\n")
                f.write(f"Concorso: {concorso_data}\n")
                f.write(f"Numeri giocati: {', '.join(numeri_giocati_sorted)}\n")
                f.write(f"Numeri estratti: {', '.join(numeri_estratti)}\n")
                f.write(f"Numeri indovinati: {', '.join(numeri_indovinati_sorted)}\n")
                f.write(f"Totale numeri indovinati: {tot_indovinati}\n")
                f.write("="*50 + "\n")
            print(f"✅ Risultati della riga {idx} salvati in 'risultati.txt'")

    else:
        print("⚠️ Non sono riuscito a recuperare i numeri estratti.")

if __name__ == "__main__":
    main()

