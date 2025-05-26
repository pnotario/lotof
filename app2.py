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
        SELECT data, n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14, n15
        FROM estrazioni_reali
        ORDER BY data
    """
    try:
        df = pd.read_sql(query, con=engine)
        return df
    except Exception as e:
        print(f"Errore nel caricamento dati: {e}")
        cols = ['data'] + [f"n{i}" for i in range(1,16)]
        return pd.DataFrame(columns=cols)

def freq_numeri_generate(df):
    numbers = []
    for _, row in df.iterrows():
        numbers.extend(row[1:].tolist())  # esclude 'data'
    return dict(Counter(numbers))

def freq_combinazioni(df):
    comb_counter = Counter()
    for _, row in df.iterrows():
        comb = tuple(sorted(row[1:].tolist()))
        comb_counter[comb] += 1
    return comb_counter

def freq_numero_per_data(df, numero):
    df['contains_num'] = df.apply(lambda r: numero in r[1:].tolist(), axis=1)
    df_sorted = df.sort_values('data')
    df_sorted['freq_cum'] = df_sorted['contains_num'].cumsum()
    return df_sorted[['data', 'freq_cum']]

app = Dash(__name__)

app.layout = html.Div([
    html.H1("Analisi Estrazioni Lotterie"),
    
    html.Label("Seleziona tipo di grafico:"),
    dcc.Dropdown(
        id='chart-type',
        options=[
            {'label': 'Frequenza Numeri Totale', 'value': 'freq_num'},
            {'label': 'Top 5 Combinazioni Frequenti', 'value': 'top_comb'},
            {'label': 'Grafico Temporale Frequenza Numero', 'value': 'time_num'},
            {'label': 'Distribuzione Frequenza Numeri', 'value': 'dist_freq'}
        ],
        value='freq_num'
    ),
    
    html.Div(id='numero-input-container', children=[
        html.Label("Seleziona numero (per grafico temporale):"),
        dcc.Input(id='numero-input', type='number', min=1, max=99, step=1, value=1)
    ], style={'display': 'none'}),
    
    dcc.Graph(id='main-chart'),
    
    dcc.Interval(
        id='interval-component',
        interval=10*1000,  # ogni 10 secondi
        n_intervals=0
    )
])

@app.callback(
    Output('numero-input-container', 'style'),
    Input('chart-type', 'value')
)
def toggle_numero_input(chart_type):
    if chart_type == 'time_num':
        return {'display': 'block'}
    else:
        return {'display': 'none'}

@app.callback(
    Output('main-chart', 'figure'),
    Input('interval-component', 'n_intervals'),
    Input('chart-type', 'value'),
    Input('numero-input', 'value')
)
def update_chart(n_intervals, chart_type, numero):
    df = load_data()
    
    if df.empty:
        return go.Figure()
    
    if chart_type == 'freq_num':
        freq = freq_numeri_generate(df)
        sorted_nums = sorted(freq.items())
        x = [str(num) for num, _ in sorted_nums]
        y = [count for _, count in sorted_nums]
        fig = go.Figure(data=go.Bar(x=x, y=y))
        fig.update_layout(title="Frequenza Numeri Totale",
                          xaxis_title="Numero",
                          yaxis_title="Frequenza")
        return fig
    
    elif chart_type == 'top_comb':
        comb_freq = freq_combinazioni(df)
        top_comb = comb_freq.most_common(5)
        
        comb_labels = [", ".join(map(str, comb)) for comb, _ in top_comb]
        counts = [count for _, count in top_comb]
        
        fig = go.Figure(go.Bar(
            x=counts[::-1],
            y=comb_labels[::-1],
            orientation='h',
            text=counts[::-1],
            textposition='auto',
            marker_color='teal',
            hovertemplate='Combinazione: %{y}<br>Frequenza: %{x}<extra></extra>'
        ))
        
        fig.update_layout(
            title="Top 5 Combinazioni Più Frequenti",
            xaxis_title="Frequenza",
            yaxis_title="Combinazione",
            yaxis=dict(autorange="reversed"),
            plot_bgcolor='white',
            margin=dict(l=150, r=20, t=50, b=50),
            height=400
        )
        return fig
    
    elif chart_type == 'time_num':
        if numero is None or numero < 1:
            return go.Figure()
        df_freq = freq_numero_per_data(df, numero)
        fig = go.Figure()
        fig.add_trace(go.Scatter(x=df_freq['data'], y=df_freq['freq_cum'],
                                 mode='lines+markers',
                                 name=f'Frequenza cumulativa numero {numero}'))
        fig.update_layout(title=f"Frequenza Cumulativa del Numero {numero} nel Tempo",
                          xaxis_title="Data",
                          yaxis_title="Frequenza cumulativa")
        return fig
    
    elif chart_type == 'dist_freq':
        freq = freq_numeri_generate(df)
        counts = list(freq.values())
        fig = go.Figure(data=go.Histogram(x=counts, nbinsx=20))
        fig.update_layout(title="Distribuzione Frequenza Numeri",
                          xaxis_title="Frequenza",
                          yaxis_title="Conteggio Numeri")
        return fig
    
    else:
        return go.Figure()

if __name__ == '__main__':
    app.run_server(debug=True)

