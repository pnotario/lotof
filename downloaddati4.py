#!/usr/bin/env python3

import time
import random
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from webdriver_manager.chrome import ChromeDriverManager

def random_delay(min_delay=1, max_delay=3):
    """Introduce un ritardo casuale per simulare il comportamento umano."""
    time.sleep(random.uniform(min_delay, max_delay))

def main():
    chrome_options = Options()
    # Rimuove le tracce di Selenium
    chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
    chrome_options.add_experimental_option("useAutomationExtension", False)

    # Simula un browser "normale"
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("start-maximized")
    chrome_options.add_argument(
        "user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.51 Safari/537.36"
    )
    
    # Modalità headless per esecuzioni da cron (senza DISPLAY)
    chrome_options.add_argument("--headless=new")  # NECESSARIA per ambienti non grafici
    
    service = Service(ChromeDriverManager().install())
    driver = webdriver.Chrome(service=service, options=chrome_options)

    # Disabilita la property navigator.webdriver via CDP
    driver.execute_cdp_cmd(
        "Page.addScriptToEvaluateOnNewDocument",
        {"source": "Object.defineProperty(navigator, 'webdriver', {get: () => undefined})"},
    )

    print("🔄 Recupero dei risultati della Lotofácil...")
    driver.get("https://loterias.caixa.gov.br/Paginas/Lotofacil.aspx")
    random_delay()

    # Salva la pagina per debug
    with open("pagina_lotofacil.html", "w", encoding="utf-8") as f:
        f.write(driver.page_source)

    try:
        # Estrazione del testo contenente concorso e data, es. "Concurso 3344 (17/03/2025)"
        span_elem = driver.find_element(By.CSS_SELECTOR, "span.ng-binding")
        raw_text = span_elem.text.strip()
        
        if "Concurso" in raw_text and "(" in raw_text:
            parte_concorso = raw_text.split("(")[0].replace("Concurso", "").strip()
            parte_data = raw_text.split("(")[1].replace(")", "").strip()
        else:
            parte_concorso = "???"
            parte_data = "???"

        # Estrazione dei numeri dalla lista
        num_elems = driver.find_elements(By.CSS_SELECTOR, "ul.simple-container.lista-dezenas.lotofacil li")
        numeri = [n.text.strip() for n in num_elems]

        driver.quit()

        if parte_concorso != "???" and numeri:
            # Crea la riga di output: concorso[TAB]data[TAB]num1[TAB]num2[...] 
            output_line = f"{parte_concorso}\t{parte_data}\t" + "\t".join(numeri)
            print(output_line)
            
            # Legge il contenuto attuale del file (se esiste)
            filename = "/home/pier/documenti/lotof/dat/dati.txt"
            try:
                with open(filename, "r", encoding="utf-8") as f:
                    old_content = f.read()
            except FileNotFoundError:
                old_content = ""
            
            # Scrive il nuovo risultato in cima al file seguito dal contenuto precedente
            with open(filename, "w", encoding="utf-8") as f:
                f.write(output_line + "\n" + old_content)
            print(f"✅ Risultato salvato in '{filename}' (in testa al file)")
        else:
            print("⚠️ Dati incompleti: non ho trovato concorso o numeri validi.")

    except Exception as e:
        print(f"❌ Errore nel parsing: {e}")
        driver.quit()

if __name__ == "__main__":
    main()

