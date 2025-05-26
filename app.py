from flask import Flask
import mysql.connector
import pandas as pd
import dash
from dash import dcc, html, Input, Output
import plotly.graph_objs as go

# Flask app
server = Flask(__name__)

# Connessione DB (modifica con i tuoi dati)
def get_db_connection():
    return mysql.connector.connect(
        host='localhost',
        user='root',
        password='sanpaolo12',
        database='lotterie'
    )

# Carica estrazioni reali dal DB
def load_real_draws():
    conn = get_db_connection()
    query = "SELECT * FROM estrazioni_reali ORDER BY data"
    df = pd.read_sql(query, conn)
    conn.close()
    return df

# Carica estrazioni generate (es. solo modello 'xgboost' o tutti)
def load_generated_draws(modello=None):
    conn = get_db_connection()
    if modello:
        query = f"SELECT * FROM estrazioni WHERE modello = '{modello}' ORDER BY id"
    else:
        query = "SELECT * FROM estrazioni ORDER BY id"
    df = pd.read_sql(query, conn)
    conn.close()
    return df

# Estrai frequenze numeri da dataframe estrazioni reali
def freq_numeri_reali(df_reali):
    numbers = []
    for col in df_reali.columns:
        if col.startswith('n'):
            numbers.extend(df_reali[col].dropna().astype(int).tolist())
    freq = pd.Series(numbers).value_counts().sort_index()
    return freq

# Estrai frequenze numeri da combinazioni generate (col combinazione es "1,2,3,...")
def freq_numeri_generate(df_gen):
    numbers = []
    for comb in df_gen['combinazione']:
        nums = map(int, comb.split(','))
        numbers.extend(nums)
    freq = pd.Series(numbers).value_counts().sort_index()
    return freq

# Inizializza Dash app
app = dash.Dash(__name__, server=server, url_base_pathname='/dashboard/')

app.layout = html.Div([
    html.H1("Dashboard Lotterie - Estrazioni Reali vs Modelli"),
    html.Label("Seleziona modello:"),
    dcc.Dropdown(
        id='model-dropdown',
        options=[
            {'label': 'Tutti', 'value': 'all'},
            {'label': 'Combinatoria', 'value': 'combinatoria'},
            {'label': 'Bayesiana', 'value': 'bayesiana'},
            {'label': 'Monte Carlo', 'value': 'monte_carlo'},
            {'label': 'Markov Chain', 'value': 'markov_chain'},
            {'label': 'Logistic Regression', 'value': 'logistic_regression'},
            {'label': 'Random Forest', 'value': 'random_forest'},
            {'label': 'XGBoost', 'value': 'xgboost'}
        ],
        value='all'
    ),
    dcc.Graph(id='freq-numbers-chart'),
])

@app.callback(
    Output('freq-numbers-chart', 'figure'),
    Input('model-dropdown', 'value')
)
def update_freq_chart(selected_model):
    df_reali = load_real_draws()
    freq_reali = freq_numeri_reali(df_reali)

    if selected_model == 'all':
        df_gen = load_generated_draws()
    else:
        df_gen = load_generated_draws(selected_model)
    freq_gen = freq_numeri_generate(df_gen)

    numbers = sorted(set(freq_reali.index).union(freq_gen.index))
    freq_reali_vals = [freq_reali.get(n, 0) for n in numbers]
    freq_gen_vals = [freq_gen.get(n, 0) for n in numbers]

    fig = go.Figure()
    fig.add_trace(go.Bar(x=numbers, y=freq_reali_vals, name='Estrazioni Reali'))
    fig.add_trace(go.Bar(x=numbers, y=freq_gen_vals, name=f'Estrazioni Modello: {selected_model}'))
    fig.update_layout(
        barmode='group',
        title='Frequenza numeri estratti - Reali vs Modello',
        xaxis_title='Numero',
        yaxis_title='Frequenza'
    )
    return fig

if __name__ == '__main__':
    server.run(debug=True, port=8050)

