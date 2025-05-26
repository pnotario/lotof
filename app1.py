from dash import Dash, dcc, html, Input, Output
import pandas as pd
import plotly.graph_objects as go
from sqlalchemy import create_engine
from collections import Counter

# Configura la connessione a MariaDB (modifica con i tuoi dati)
DATABASE_URL = "mysql+pymysql://root:sanpaolo12@localhost:3306/lotterie"
engine = create_engine(DATABASE_URL)

def load_data():
    query = """
        SELECT n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14, n15
        FROM estrazioni_reali
    """
    try:
        df = pd.read_sql(query, con=engine)
        return df
    except Exception as e:
        print(f"Errore nel caricamento dati: {e}")
        return pd.DataFrame(columns=[f"n{i}" for i in range(1,16)])

def freq_numeri_generate(df):
    numbers = []
    for _, row in df.iterrows():
        numbers.extend(row.tolist())
    return dict(Counter(numbers))

app = Dash(__name__)

app.layout = html.Div([
    html.H1("Frequenza Numeri Estrazioni"),
    dcc.Graph(id='freq-chart'),
    dcc.Interval(
        id='interval-component',
        interval=10*1000,  # ogni 10 secondi
        n_intervals=0
    )
])

@app.callback(
    Output('freq-chart', 'figure'),
    Input('interval-component', 'n_intervals')
)
def update_freq_chart(n):
    df_gen = load_data()
    freq_gen = freq_numeri_generate(df_gen)

    if not freq_gen:
        return go.Figure()

    sorted_nums = sorted(freq_gen.items())
    x = [str(num) for num, _ in sorted_nums]
    y = [count for _, count in sorted_nums]

    fig = go.Figure(data=go.Bar(x=x, y=y))
    fig.update_layout(
        title="Frequenza Numeri Estratti",
        xaxis_title="Numero",
        yaxis_title="Frequenza"
    )
    return fig

if __name__ == '__main__':
    app.run_server(debug=True)

