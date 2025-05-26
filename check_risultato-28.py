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
    
    service = Service(ChromeDriverManager().install())
    driver = webdriver.Chrome(service=service, options=chrome_options)

    driver.execute_cdp_cmd(
        "Page.addScriptToEvaluateOnNewDocument",
        {"source": "Object.defineProperty(navigator, 'webdriver', {get: () => undefined})"},
    )

    driver.get("https://loterias.caixa.gov.br/Paginas/Lotofacil.aspx")
    random_delay()

    try:
        WebDriverWait(driver, 10).until(EC.presence_of_all_elements_located((By.CSS_SELECTOR, "ul.simple-container.lista-dezenas.lotofacil li")))
        num_elems = driver.find_elements(By.CSS_SELECTOR, "ul.simple-container.lista-dezenas.lotofacil li")
        numeri_estratti = {n.text.strip() for n in num_elems}

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
    file_puntata = './dat/puntata.txt'
    
    # Formatta il file prima di utilizzarlo
    format_numbers_inplace(file_puntata)
    
    try:
        with open(file_puntata, 'r', encoding='utf-8') as f:
            righe = f.readlines()
    except FileNotFoundError:
        print("❌ File 'puntata.txt' non trovato.")
        return

    print("🔄 Recupero dei numeri estratti della Lotofácil...")
    numeri_estratti, concorso_data = recupera_numeri_estratti_e_concorso()

    sommario = []

    if numeri_estratti:
        numeri_estratti = sorted(numeri_estratti)
        print(f"\nConcorso: {concorso_data}")
        print(f"Numeri estratti: {', '.join(numeri_estratti)}\n")
        print("="*50)

        for idx, riga in enumerate(righe, start=1):
            numeri_giocati = set(riga.strip().replace("\t", " ").split())
            numeri_giocati_sorted = sorted(numeri_giocati)

            numeri_indovinati, tot_indovinati = confronta_numeri(numeri_giocati, numeri_estratti)
            numeri_indovinati_sorted = sorted(numeri_indovinati)

            print(f"📝 Risultati per la riga {idx}:")
            print(f"  Concorso: {concorso_data}")
            print(f"  Numeri giocati: {', '.join(numeri_giocati_sorted)}")
            print(f"  Numeri indovinati: {', '.join(numeri_indovinati_sorted)}")
            print(f"\033[1m  Totale numeri indovinati: {tot_indovinati}\033[0m")
            print("-"*50)

            sommario.append((idx, tot_indovinati))

        # Ordinamento del sommario in ordine decrescente per numero di numeri indovinati
        sommario.sort(key=lambda x: x[1], reverse=True)
        
        print("\n📊 Sommario dei risultati (ordinato per numeri indovinati):")
        for riga_idx, tot_indovinati in sommario:
            if tot_indovinati in [11, 12, 13, 14]:
                print(f"\033[1mRiga {riga_idx}: {tot_indovinati} numeri indovinati\033[0m")  # Bold
            elif tot_indovinati == 15:
                print(f"\033[1;5mRiga {riga_idx}: {tot_indovinati} numeri indovinati\033[0m")  # Bold + Blink
            else:
                print(f"Riga {riga_idx}: {tot_indovinati} numeri indovinati")
    else:
        print("⚠️ Non sono riuscito a recuperare i numeri estratti.")

if __name__ == "__main__":
    main()
