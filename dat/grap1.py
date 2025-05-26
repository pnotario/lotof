import sys
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg as FigureCanvas
from matplotlib.figure import Figure
from PyQt5.QtWidgets import QApplication, QTabWidget, QVBoxLayout, QWidget

# Funzione per leggere i dati dal file
def leggi_dati():
    sequenze = []
    with open('dati.txt', 'r') as file:
        for riga in file:
            # Ignora la prima e la seconda colonna (ID e data)
            numeri = riga.strip().split('\t')[2:]
            sequenze.append([int(numero) for numero in numeri])
    return sequenze

# Funzione per generare i grafici
def crea_grafici(sequenze):
    figures = []

    # Unisci tutte le liste in una sola
    tutti_numeri = [numero for sequenza in sequenze for numero in sequenza]

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
    for i, sequenza in enumerate(sequenze):
        ax2.plot(sequenza, label=f'Sequenza {i+1}')
    ax2.set_title('Andamento dei Numeri nel Tempo')
    ax2.set_xlabel('Posizione')
    ax2.set_ylabel('Valore')
    ax2.legend()
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

        self.sequenze = leggi_dati()
        self.figures = crea_grafici(self.sequenze)

        for i, fig in enumerate(self.figures):
            tab = QWidget()
            layout = QVBoxLayout()
            canvas = FigureCanvas(fig)
            layout.addWidget(canvas)
            tab.setLayout(layout)
            self.addTab(tab, f'Tab {i + 1}')

if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = Window()
    window.resize(800, 600)
    window.show()
    sys.exit(app.exec_())

