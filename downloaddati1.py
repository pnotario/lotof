#!/usr/bin/env python3

import time
import random
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from webdriver_manager.chrome import ChromeDriverManager

def random_delay(min_delay=1, max_delay=3):
    """Introduci un ritardo casuale tra le azioni, per sembrare più umano."""
    time.sleep(random.uniform(min_delay, max_delay))

def main():
    chrome_options = Options()
    # Rimuovi i segni di Selenium
    chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
    chrome_options.add_experimental_option('useAutomationExtension', False)

    # Simula un browser “normale”
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("start-maximized")
    chrome_options.add_argument(
        "user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.51 Safari/537.36"
    )
    # Se vuoi vederlo in azione, NON aggiungere "--headless"
    # chrome_options.add_argument("--headless")

    service = Service(ChromeDriverManager().install())
    driver = webdriver.Chrome(service=service, options=chrome_options)

    # Disabilita la property navigator.webdriver via CDP
    driver.execute_cdp_cmd(
        "Page.addScriptToEvaluateOnNewDocument",
        {
            "source": """
            Object.defineProperty(navigator, 'webdriver', {
              get: () => undefined
            })
            """
        },
    )

    print("🔄 Recupero dei risultati della Lotofácil...")
    driver.get("https://loterias.caixa.gov.br/Paginas/Lotofacil.aspx")
    random_delay()

    # Salva la pagina per debug
    with open("pagina_lotofacil.html", "w", encoding="utf-8") as f:
        f.write(driver.page_source)

    try:
        # Estrarre il testo del concorso e data: es. "Concurso 3344 (17/03/2025)"
        span_elem = driver.find_element(By.CSS_SELECTOR, "span.ng-binding")
        raw_text = span_elem.text.strip()  # "Concurso 3344 (17/03/2025)"

        # Parse: "Concurso 3344 (17/03/2025)"
        # => concorso = "3344", data = "17/03/2025"
        if "Concurso" in raw_text and "(" in raw_text:
            parte_concorso = raw_text.split("(")[0].replace("Concurso", "").strip()  # "3344"
            parte_data = raw_text.split("(")[1].replace(")", "").strip()             # "17/03/2025"
        else:
            parte_concorso = "???"
            parte_data = "???"

        # Estrarre i numeri dal `ul.simple-container.lista-dezenas.lotofacil li`
        num_elems = driver.find_elements(By.CSS_SELECTOR, "ul.simple-container.lista-dezenas.lotofacil li")
        numeri = [n.text.strip() for n in num_elems]

        driver.quit()

        if parte_concorso != "???" and numeri:
            print(f"✅ Concorso: {parte_concorso} | Data: {parte_data}")
            print(f"🔢 Numeri estratti: {', '.join(numeri)}")
        else:
            print("⚠️ Non ho trovato concorso o numeri validi.")
    except Exception as e:
        print(f"❌ Errore nel parsing: {e}")
        driver.quit()

if __name__ == "__main__":
    main()

