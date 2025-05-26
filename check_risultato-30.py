import time
import random
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
from tabulate import tabulate

class Colori:
    ROSSO = '\033[91m'
    VERDE = '\033[92m'
    GIALLO = '\033[93m'
    BLU = '\033[94m'
    MAGENTA = '\033[95m'
    BIANCO = '\033[97m'
    RESET = '\033[0m'

def random_delay(min_delay=1, max_delay=3):
    time.sleep(random.uniform(min_delay, max_delay))

def format_numbers_inplace(file_path):
    try:
        with open(file_path, 'r+', encoding='utf-8') as f:
            lines = []
            for i, line in enumerate(f, 1):
                try:
                    nums = [f"{int(num.strip()):02}" for num in line.split()]
                    lines.append('\t'.join(nums) + '\n')
                except ValueError:
                    print(f"{Colori.ROSSO}⚠️ Errore formato riga {i}: {line.strip()}{Colori.RESET}")
                    lines.append(line)
            f.seek(0)
            f.writelines(lines)
            f.truncate()
    except FileNotFoundError:
        print(f"{Colori.ROSSO}❌ Errore: Il file '{file_path}' non esiste.{Colori.RESET}")

def recupera_numeri_estratti_e_concorso():
    chrome_options = Options()
    chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
    chrome_options.add_experimental_option("useAutomationExtension", False)
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("start-maximized")
    chrome_options.add_argument(
        "user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.51 Safari/537.36"
    )

    service = Service(ChromeDriverManager().install())
    driver = webdriver.Chrome(service=service, options=chrome_options)

    driver.execute_cdp_cmd(
        "Page.addScriptToEvaluateOnNewDocument",
        {"source": "Object.defineProperty(navigator, 'webdriver', {get: () => undefined})"},
    )

    print(f"{Colori.GIALLO}🌐 Apertura pagina ufficiale Lotofácil...{Colori.RESET}")
    driver.get("https://loterias.caixa.gov.br/Paginas/Lotofacil.aspx")
    random_delay()

    try:
        WebDriverWait(driver, 20).until(
            EC.presence_of_all_elements_located(
                (By.CSS_SELECTOR, "ul.simple-container.lista-dezenas.lotofacil li")
            )
        )

        print(f"{Colori.VERDE}✅ Elementi dei numeri trovati!{Colori.RESET}")
        num_elems = driver.find_elements(By.CSS_SELECTOR, "ul.simple-container.lista-dezenas.lotofacil li")

        numeri_estratti = []
        for n in num_elems:
            numero = n.text.strip()
            print(f"{Colori.BLU}🔢 Numero trovato: {numero}{Colori.RESET}")  # DEBUG
            if numero.isdigit():
                numeri_estratti.append(f"{int(numero):02}")

        numeri_estratti = sorted(numeri_estratti, key=lambda x: int(x))

        concorso_elem = driver.find_element(By.CSS_SELECTOR, "span.ng-binding")
        concorso_data = concorso_elem.text.strip()

        driver.quit()
        return numeri_estratti, concorso_data

    except Exception as e:
        print(f"{Colori.ROSSO}❌ Errore durante il recupero dei numeri estratti: {e}{Colori.RESET}")
        driver.quit()
        return [], ""

def confronta_numeri(giocati, estratti):
    numeri_indovinati = giocati.intersection(estratti)
    return numeri_indovinati, len(numeri_indovinati)

def main():
    print(f"{Colori.BLU}🎲 Analisi Lotofácil in corso...{Colori.RESET}")
    
    file_puntata = './dat/puntata.txt'
    
    format_numbers_inplace(file_puntata)
    
    try:
        with open(file_puntata, 'r', encoding='utf-8') as f:
            righe = f.readlines()
    except FileNotFoundError:
        print(f"{Colori.ROSSO}❌ File 'puntata.txt' non trovato.{Colori.RESET}")
        return

    print(f"{Colori.VERDE}🔄 Recupero dei numeri estratti della Lotofácil...{Colori.RESET}")
    numeri_estratti, concorso_data = recupera_numeri_estratti_e_concorso()

    if numeri_estratti:
        print(f"\n{Colori.BLU}Concorso: {concorso_data}{Colori.RESET}")
        print(f"{Colori.BLU}Numeri estratti: {', '.join(numeri_estratti)}{Colori.RESET}\n")
        print("="*50)

        tabella_risultati = []
        sommario = []

        for idx, riga in enumerate(righe, start=1):
            numeri_giocati = set(riga.strip().replace("\t", " ").split())
            numeri_giocati_sorted = sorted(numeri_giocati)

            numeri_indovinati, tot_indovinati = confronta_numeri(numeri_giocati, set(numeri_estratti))
            numeri_indovinati_sorted = sorted(numeri_indovinati)

            tabella_risultati.append([
                f"Riga {idx}",
                ', '.join(numeri_giocati_sorted),
                ', '.join(numeri_indovinati_sorted),
                f"{tot_indovinati} numeri"
            ])

            sommario.append((idx, tot_indovinati))

        print(tabulate(tabella_risultati, headers=["Riga", "Numeri Giocati", "Numeri Indovinati", "Totale Indovinati"], tablefmt="grid"))

        sommario.sort(key=lambda x: x[1], reverse=True)

        print("\n{0}📊 Sommario dei risultati (ordinato per numeri indovinati):{1}".format(Colori.BLU, Colori.RESET))
        VINCITORI_IMPORTANTI = {15: "🎉 JACKPOT!", 14: "🏆 Vittoria maggiore!", 13: "💰 Vincita significativa!"}
        for riga_idx, tot_indovinati in sommario:
            if tot_indovinati in VINCITORI_IMPORTANTI:
                print(f"\n{Colori.MAGENTA}{VINCITORI_IMPORTANTI[tot_indovinati]} - Riga {riga_idx}{Colori.RESET}")
            elif tot_indovinati in [11, 12]:
                print(f"{Colori.VERDE}Riga {riga_idx}: {tot_indovinati} numeri indovinati{Colori.RESET}")
            else:
                print(f"Riga {riga_idx}: {tot_indovinati} numeri indovinati")
    else:
        print(f"{Colori.ROSSO}⚠️ Non sono riuscito a recuperare i numeri estratti.{Colori.RESET}")

    print(f"\n{Colori.VERDE}✅ Analisi completata con successo!{Colori.RESET}")

if __name__ == "__main__":
    main()

