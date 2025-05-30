from dash import Dash, dcc, html, Input, Output, State
import pymysql
import pandas as pd
import plotly.graph_objects as go
import plotly.express as px
from sqlalchemy import create_engine
from collections import Counter
import io


app = Dash(__name__)
server = app.server  # Per Gunicorn

# Tema scuro/light
app.layout = html.Div([
    html.H1("Dashboard Lotterie - Analisi Estrazioni"),
    html.Div([
        html.Label("Tema scuro:"),
        dcc.Checklist(
            id='dark-theme-toggle',
            options=[{'label': '', 'value': 'dark'}],
            value=[],
            style={'display': 'inline-block', 'marginRight': '20px'}
        ),
        html.Span(id='theme-label', children="Light mode", style={'fontWeight': 'bold'})
    ], style={'margin-bottom': '18px'}),
    html.Div([
        html.Label("Utente DB:"),
        dcc.Input(id='db-user', type='text', value='mio_utente_default'),
        html.Label("Password DB:"),
        dcc.Input(id='db-password', type='password', value='mia_password_default'),
        html.Label("Host DB:"),
        dcc.Input(id='db-host', type='text', value='localhost'),
        html.Label("Porta DB:"),
        dcc.Input(id='db-port', type='number', value=3306, min=1, max=65535),
        html.Label("Nome Database:"),
        dcc.Input(id='db-name', type='text', value='lotterie'),
        html.Button("Carica Dati", id='load-data-btn'),
    ], style={'margin-bottom': '18px', 'display': 'flex', 'flexWrap': 'wrap', 'gap': '10px'}),
    html.Div([
        html.Label("Seleziona intervallo date:"),
        dcc.DatePickerRange(
            id='date-range-picker',
            start_date_placeholder_text="Data inizio",
            end_date_placeholder_text="Data fine",
            calendar_orientation='horizontal',
            minimum_nights=0,
            display_format='DD/MM/YYYY',
        )
    ], style={'margin-bottom': '18px'}),
    html.Div([
        html.Label("Seleziona numeri per grafico temporale (Ctrl/cmd per selezione multipla):"),
        dcc.Dropdown(id='numeri-temporali', multi=True, placeholder="Scegli uno o più numeri"),
    ], style={'margin-bottom': '18px'}),
    html.Div([
        html.Div(dcc.Graph(id='freq-num-chart'), style={'width': '100%', 'maxWidth': '700px', 'display': 'inline-block', 'verticalAlign': 'top'}),
        html.Div(dcc.Graph(id='top-comb-chart'), style={'width': '100%', 'maxWidth': '700px', 'display': 'inline-block', 'verticalAlign': 'top'}),
    ], style={'display': 'flex', 'flexWrap': 'wrap', 'gap': '30px', 'margin-bottom': '32px'}),
    html.Div([
        html.Div(dcc.Graph(id='dist-freq-chart'), style={'width': '100%', 'maxWidth': '700px', 'display': 'inline-block'}),
        html.Div(dcc.Graph(id='time-num-chart'), style={'width': '100%', 'maxWidth': '700px', 'display': 'inline-block'}),
    ], style={'display': 'flex', 'flexWrap': 'wrap', 'gap': '30px'}),
    html.Div(id='info-panel', style={'marginTop': '30px', 'fontWeight': 'bold', 'fontSize': '18px'}),
    dcc.Store(id='stored-data')
], id='main-div')

def create_engine_from_params(user, password, host, port, dbname):
    conn_str = f"mysql+pymysql://{user}:{password}@{host}:{port}/{dbname}"
    return create_engine(conn_str)

def load_data(engine):
    query = """
        SELECT data, n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14, n15
        FROM estrazioni_reali
        ORDER BY data
    """
    try:
        df = pd.read_sql(query, con=engine)
        df['data'] = pd.to_datetime(df['data'])
        return df
    except Exception as e:
        print(f"Errore nel caricamento dati: {e}")
        cols = ['data'] + [f"n{i}" for i in range(1,16)]
        return pd.DataFrame(columns=cols)

def filter_data_by_date(df, start_date, end_date):
    if start_date:
        df = df[df['data'] >= pd.to_datetime(start_date)]
    if end_date:
        df = df[df['data'] <= pd.to_datetime(end_date)]
    return df

def freq_numeri_generate(df):
    if df.empty:
        return {}
    numbers = []
    for _, row in df.iterrows():
        numbers.extend(row[1:].tolist())  # esclude 'data'
    return dict(Counter(numbers))

def freq_combinazioni(df):
    if df.empty:
        return Counter()
    comb_counter = Counter()
    for _, row in df.iterrows():
        comb = tuple(sorted(row[1:].tolist()))
        comb_counter[comb] += 1
    return comb_counter

def freq_numero_per_data(df, numero):
    if df.empty:
        return pd.DataFrame()
    df['contains_num'] = df.apply(lambda r: numero in r[1:].tolist(), axis=1)
    df_sorted = df.sort_values('data')
    df_sorted['freq_cum'] = df_sorted['contains_num'].cumsum()
    return df_sorted[['data', 'freq_cum']]

def safe_read_json(data_json):
    if not data_json:
        return pd.DataFrame()
    try:
        df = pd.read_json(io.StringIO(data_json), orient='split')
        return df
    except Exception as e:
        print(f"[DEBUG] Errore parsing JSON: {e}")
        return pd.DataFrame()

@app.callback(
    Output('stored-data', 'data'),
    Output('numeri-temporali', 'options'),
    Input('load-data-btn', 'n_clicks'),
    State('db-user', 'value'),
    State('db-password', 'value'),
    State('db-host', 'value'),
    State('db-port', 'value'),
    State('db-name', 'value'),
    prevent_initial_call=True
)
def load_and_store_data(n_clicks, user, password, host, port, dbname):
    try:
        engine = create_engine_from_params(user, password, host, port, dbname)
        df = load_data(engine)
        if df.empty:
            print("[DEBUG] DataFrame vuoto dopo caricamento dati.")
            return None, []
        data_json = df.to_json(date_format='iso', orient='split')
        numeri = sorted({n for col in df.columns[1:] for n in df[col].dropna().unique()})
        options = [{'label': str(n), 'value': int(n)} for n in numeri]
        print("[DEBUG] Dati caricati correttamente.")
        return data_json, options
    except Exception as e:
        print(f"Errore connessione o caricamento dati: {e}")
        return None, []

@app.callback(
    Output('freq-num-chart', 'figure'),
    Input('stored-data', 'data'),
    Input('date-range-picker', 'start_date'),
    Input('date-range-picker', 'end_date'),
    Input('dark-theme-toggle', 'value')
)
def update_freq_num_chart(data_json, start_date, end_date, dark_theme):
    df = safe_read_json(data_json)
    if df.empty:
        return go.Figure(layout={"annotations": [{"text": "Carica i dati per visualizzare il grafico", "xref": "paper", "yref": "paper", "showarrow": False, "font": {"size": 18}}]})
    df = filter_data_by_date(df, start_date, end_date)
    if df.empty:
        return go.Figure(layout={"annotations": [{"text": "Nessun dato nell'intervallo selezionato", "xref": "paper", "yref": "paper", "showarrow": False, "font": {"size": 18}}]})
    freq = freq_numeri_generate(df)
    if not freq:
        return go.Figure(layout={"annotations": [{"text": "Nessuna frequenza calcolata", "xref": "paper", "yref": "paper", "showarrow": False, "font": {"size": 18}}]})
    sorted_nums = sorted(freq.items(), key=lambda x: x[1], reverse=True)
    x = [str(num) for num, _ in sorted_nums]
    y = [count for _, count in sorted_nums]
    colors = y
    fig = go.Figure(go.Bar(
        x=x, y=y,
        marker=dict(color=colors, colorscale='Viridis', showscale=True, colorbar=dict(title='Frequenza')),
        text=y, textposition='outside',
        hovertemplate='Numero: %{x}<br>Frequenza: %{y}<extra></extra>'
    ))
    fig.update_layout(
        title="Frequenza Numeri Totale",
        xaxis_title="Numero",
        yaxis_title="Frequenza",
        xaxis_tickangle=-45,
        margin=dict(l=40, r=40, t=60, b=120),
        plot_bgcolor='#222' if 'dark' in dark_theme else 'white',
        paper_bgcolor='#222' if 'dark' in dark_theme else 'white',
        font_color='white' if 'dark' in dark_theme else 'black',
        height=500
    )
    return fig

@app.callback(
    Output('top-comb-chart', 'figure'),
    Input('stored-data', 'data'),
    Input('date-range-picker', 'start_date'),
    Input('date-range-picker', 'end_date'),
    Input('dark-theme-toggle', 'value')
)
def update_top_comb_chart(data_json, start_date, end_date, dark_theme):
    df = safe_read_json(data_json)
    if df.empty:
        return go.Figure(layout={"annotations": [{"text": "Carica i dati per visualizzare il grafico", "xref": "paper", "yref": "paper", "showarrow": False, "font": {"size": 18}}]})
    df = filter_data_by_date(df, start_date, end_date)
    if df.empty:
        return go.Figure(layout={"annotations": [{"text": "Nessun dato nell'intervallo selezionato", "xref": "paper", "yref": "paper", "showarrow": False, "font": {"size": 18}}]})
    comb_freq = freq_combinazioni(df)
    top_comb = comb_freq.most_common(5)
    if not top_comb:
        return go.Figure(layout={"annotations": [{"text": "Nessuna combinazione trovata", "xref": "paper", "yref": "paper", "showarrow": False, "font": {"size": 18}}]})
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
        plot_bgcolor='#222' if 'dark' in dark_theme else 'white',
        paper_bgcolor='#222' if 'dark' in dark_theme else 'white',
        font_color='white' if 'dark' in dark_theme else 'black',
        margin=dict(l=150, r=20, t=50, b=50),
        height=400
    )
    return fig

@app.callback(
    Output('dist-freq-chart', 'figure'),
    Input('stored-data', 'data'),
    Input('date-range-picker', 'start_date'),
    Input('date-range-picker', 'end_date'),
    Input('dark-theme-toggle', 'value')
)
def update_dist_freq_chart(data_json, start_date, end_date, dark_theme):
    df = safe_read_json(data_json)
    if df.empty:
        return go.Figure(layout={"annotations": [{"text": "Carica i dati per visualizzare il grafico", "xref": "paper", "yref": "paper", "showarrow": False, "font": {"size": 18}}]})
    df = filter_data_by_date(df, start_date, end_date)
    if df.empty:
        return go.Figure(layout={"annotations": [{"text": "Nessun dato nell'intervallo selezionato", "xref": "paper", "yref": "paper", "showarrow": False, "font": {"size": 18}}]})
    freq = freq_numeri_generate(df)
    counts = list(freq.values())
    if not counts:
        return go.Figure(layout={"annotations": [{"text": "Nessuna frequenza trovata", "xref": "paper", "yref": "paper", "showarrow": False, "font": {"size": 18}}]})
    # Animazione: la distribuzione cambia col filtro date
    fig = px.histogram(
        x=counts,
        nbins=20,
        histnorm='probability density',
        title="Distribuzione Frequenza Numeri",
        labels={'x': 'Frequenza', 'y': 'Densità'},
        opacity=0.75,
        color_discrete_sequence=['teal'],
        animation_frame=None
    )
    fig.update_layout(
        bargap=0.1,
        plot_bgcolor='#222' if 'dark' in dark_theme else 'white',
        paper_bgcolor='#222' if 'dark' in dark_theme else 'white',
        font_color='white' if 'dark' in dark_theme else 'black',
        height=450
    )
    fig.add_trace(go.Box(
        x=counts,
        boxpoints='all',
        jitter=0.5,
        pointpos=-1.8,
        marker_color='darkcyan',
        name='Distribuzione valori',
        yaxis='y2'
    ))
    fig.update_layout(
        yaxis2=dict(
            domain=[0, 0.2],
            anchor='x',
            showgrid=False,
            zeroline=False,
            showticklabels=False
        ),
        margin=dict(t=50, b=50)
    )
    return fig

@app.callback(
    Output('time-num-chart', 'figure'),
    Output('info-panel', 'children'),
    Input('stored-data', 'data'),
    Input('numeri-temporali', 'value'),
    Input('date-range-picker', 'start_date'),
    Input('date-range-picker', 'end_date'),
    Input('dark-theme-toggle', 'value')
)
def update_time_num_chart(data_json, numeri, start_date, end_date, dark_theme):
    df = safe_read_json(data_json)
    if df.empty or not numeri:
        return go.Figure(layout={"annotations": [{"text": "Carica i dati e seleziona almeno un numero", "xref": "paper", "yref": "paper", "showarrow": False, "font": {"size": 18}}]}), ""
    df = filter_data_by_date(df, start_date, end_date)
    if df.empty:
        return go.Figure(layout={"annotations": [{"text": "Nessun dato nell'intervallo selezionato", "xref": "paper", "yref": "paper", "showarrow": False, "font": {"size": 18}}]}), ""
    fig = go.Figure()
    info = []
    for numero in numeri:
        df_freq = freq_numero_per_data(df, numero)
        if df_freq.empty:
            continue
        df_freq['data'] = pd.to_datetime(df_freq['data'])
        fig.add_trace(go.Scatter(
            x=df_freq['data'],
            y=df_freq['freq_cum'],
            mode='lines+markers',
            name=f'Numero {numero}',
            hovertemplate='Data: %{x|%d-%m-%Y}<br>Frequenza cumulativa: %{y}<extra></extra>'
        ))
        info.append(f"Numero {numero}: max {df_freq['freq_cum'].max()} estrazioni")
    fig.update_layout(
        title="Frequenza Cumulativa dei Numeri Selezionati nel Tempo",
        xaxis_title="Data",
        yaxis_title="Frequenza cumulativa",
        plot_bgcolor='#222' if 'dark' in dark_theme else 'white',
        paper_bgcolor='#222' if 'dark' in dark_theme else 'white',
        font_color='white' if 'dark' in dark_theme else 'black',
        xaxis=dict(
            rangeselector=dict(
                buttons=list([
                    dict(count=1, label="1m", step="month", stepmode="backward"),
                    dict(count=3, label="3m", step="month", stepmode="backward"),
                    dict(count=6, label="6m", step="month", stepmode="backward"),
                    dict(step="all")
                ])
            ),
            rangeslider=dict(visible=True),
            type="date"
        ),
        yaxis=dict(fixedrange=False)
    )
    return fig, " | ".join(info)

@app.callback(
    Output('main-div', 'style'),
    Output('theme-label', 'children'),
    Input('dark-theme-toggle', 'value')
)
def update_theme(dark_theme):
    if 'dark' in dark_theme:
        return {'backgroundColor': '#222', 'color': 'white', 'minHeight': '100vh'}, "Dark mode"
    else:
        return {'backgroundColor': 'white', 'color': 'black', 'minHeight': '100vh'}, "Light mode"

if __name__ == '__main__':
    app.run_server(debug=False)

