import sys
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.figure import Figure
from PyQt5.QtWidgets import QApplication, QTabWidget, QVBoxLayout, QWidget

# Funzione per leggere i dati dal file
def leggi_dati():
    dati = []
    with open('dati.txt', 'r') as file:
        for riga in file:
            colonne = riga.strip().split('\t')
            if len(colonne) >= 3:  # Controllo per almeno tre colonne
                data = colonne[1]
                anno = int(data.split('/')[2])  # Estrae l'anno dalla data
                numeri = [int(numero) for numero in colonne[2:]]
                dati.append((anno, numeri))
    return dati

# Funzione per generare i grafici
def crea_grafici(dati):
    figures = []

    # Unisci tutte le liste in una sola per il grafico a barre
    tutti_numeri = [numero for _, sequenza in dati for numero in sequenza]

    # Grafico a barre per la frequenza dei numeri
    fig1 = Figure()
    ax1 = fig1.add_subplot(111)
    frequenze = {}
    for numero in tutti_numeri:
        if numero in frequenze:
            frequenze[numero] += 1
        else:
            frequenze[numero] = 1
    ax1.bar(frequenze.keys(), frequenze.values())
    ax1.set_title('Frequenza dei Numeri')
    ax1.set_xlabel('Numero')
    ax1.set_ylabel('Frequenza')
    figures.append(fig1)

    # Grafico a linee per l'andamento dei numeri nel tempo
    fig2 = Figure()
    ax2 = fig2.add_subplot(111)
    for _, sequenza in dati:
        ax2.plot(sequenza)
    ax2.set_title('Andamento dei Numeri nel Tempo')
    ax2.set_xlabel('Posizione')
    ax2.set_ylabel('Valore')
    figures.append(fig2)

    # Grafico a istogramma per la distribuzione dei numeri
    fig3 = Figure()
    ax3 = fig3.add_subplot(111)
    ax3.hist(tutti_numeri, bins=range(min(tutti_numeri), max(tutti_numeri)+2), align='left', rwidth=0.8)
    ax3.set_title('Distribuzione dei Numeri')
    ax3.set_xlabel('Numero')
    ax3.set_ylabel('Frequenza')
    figures.append(fig3)

    # Grafico di probabilità cumulativa (CDF)
    fig4 = Figure()
    ax4 = fig4.add_subplot(111)
    sorted_data = sorted(tutti_numeri)
    cdf = np.arange(len(sorted_data)) / len(sorted_data)
    ax4.plot(sorted_data, cdf)
    ax4.set_title('Probabilità Cumulativa')
    ax4.set_xlabel('Numero')
    ax4.set_ylabel('Probabilità Cumulativa')
    figures.append(fig4)

    return figures

# Creazione della finestra con tabs
class Window(QTabWidget):
    def __init__(self):
        super().__init__()

        self.dati = leggi_dati()  # Legge i dati dal file
        self.figures = crea_grafici(self.dati)  # Genera i grafici e li salva in self.figures

        # Tab 1, 3, e 4 rimangono invariati
        for i in [0, 2, 3]:
            tab = QWidget()
            layout = QVBoxLayout()
            canvas = FigureCanvas(self.figures[i])
            layout.addWidget(canvas)
            tab.setLayout(layout)
            self.addTab(tab, f'Tab {i + 1}')

        # Creiamo un nuovo QTabWidget per il secondo tab
        tab2 = QTabWidget()
        
        # Suddividiamo il secondo grafico in sotto-tab per ogni anno
        anni = set(anno for anno, _ in self.dati)
        for anno in sorted(anni):
            sub_tab = QWidget()
            layout = QVBoxLayout()
            sub_fig = Figure(dpi=150)  # Imposta DPI per alta risoluzione
            sub_ax = sub_fig.add_subplot(111)
            
            # Plottiamo solo le sequenze dell'anno corrente
            sequenze_anno = [sequenza for a, sequenza in self.dati if a == anno]
            for i, sequenza in enumerate(sequenze_anno):
                sub_ax.plot(sequenza, label=f'Sequenza {i+1}')
            sub_ax.set_title(f'Andamento dei Numeri nel Tempo ({anno})', fontsize=14)  # Aumenta la dimensione del titolo
            sub_ax.set_xlabel('Posizione', fontsize=12)
            sub_ax.set_ylabel('Valore', fontsize=12)
            sub_ax.legend(loc='upper right', fontsize=10)  # Personalizza la legenda
            
            canvas = FigureCanvas(sub_fig)
            layout.addWidget(canvas)
            sub_tab.setLayout(layout)
            tab2.addTab(sub_tab, f'Anno {anno}')

        self.insertTab(1, tab2, 'Tab 2')

if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = Window()
    window.resize(800, 600)
    window.show()
    sys.exit(app.exec_())

