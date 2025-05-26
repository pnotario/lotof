import time
import random
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from webdriver_manager.chrome import ChromeDriverManager

# Impostazione delle opzioni di Chrome
chrome_options = Options()
chrome_options.add_argument("--disable-gpu")  # Disabilita la GPU (utile per alcuni ambienti)
chrome_options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36")
# chrome_options.add_argument("--headless")  # Commenta o rimuovi se vuoi vedere il browser

# Avvia il driver Chrome
driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=chrome_options)

# Funzione per un ritardo casuale tra le azioni
def random_delay(min_delay=1, max_delay=5):
    delay = random.uniform(min_delay, max_delay)
    time.sleep(delay)

# Vai alla pagina della Lotofácil
print("🔄 Recupero degli ultimi risultati della Lotofácil...")
driver.get("https://loterias.caixa.gov.br/Paginas/Lotofacil.aspx")
random_delay()  # Ritardo casuale tra le richieste

# Salva la pagina per il debug
with open("pagina_lotofacil.html", "w", encoding="utf-8") as f:
    f.write(driver.page_source)

# Estrazione dei numeri dalla lista
try:
    # Trova l'elemento della lista con i numeri
    lista_numeri = driver.find_elements(By.CSS_SELECTOR, "ul.simple-container.lista-dezenas.lotofacil li")
    numeri = [numero.text.strip() for numero in lista_numeri]
    
    if numeri:
        print(f"✅ Numeri del concorso: {', '.join(numeri)}")
    else:
        print("❌ Nessun numero trovato nella lista.")

except Exception as e:
    print(f"❌ Errore nel parsing: {str(e)}")

# Chiudi il browser
driver.quit()

