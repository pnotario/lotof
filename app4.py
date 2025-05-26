from dash import Dash, dcc, html, Input, Output, State
import pandas as pd
import plotly.graph_objects as go
import plotly.express as px
from sqlalchemy import create_engine
from collections import Counter

app = Dash(__name__)

app.layout = html.Div([
    html.H1("Analisi Estrazioni Lotterie"),
    
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
        
        html.Button("Aggiorna Connessione", id='update-conn-btn')
    ], style={'margin-bottom': '20px'}),
    
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
    
    dcc.Graph(id='main-chart')
])

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

@app.callback(
    Output('numero-input-container', 'style'),
    Input('chart-type', 'value')
)
def toggle_numero_input(chart_type):
    return {'display': 'block'} if chart_type == 'time_num' else {'display': 'none'}

@app.callback(
    Output('main-chart', 'figure'),
    Input('update-conn-btn', 'n_clicks'),
    Input('chart-type', 'value'),
    Input('numero-input', 'value'),
    State('db-user', 'value'),
    State('db-password', 'value'),
    State('db-host', 'value'),
    State('db-port', 'value'),
    State('db-name', 'value'),
    prevent_initial_call=True
)
def update_chart(n_clicks, chart_type, numero, user, password, host, port, dbname):
    if n_clicks is None:
        return go.Figure()
    try:
        engine = create_engine_from_params(user, password, host, port, dbname)
    except Exception as e:
        print(f"Errore nella creazione della connessione: {e}")
        return go.Figure()

    df = load_data(engine)
    if df.empty:
        return go.Figure()

    if chart_type == 'freq_num':
        freq = freq_numeri_generate(df)
        sorted_nums = sorted(freq.items(), key=lambda x: x[1], reverse=True)
        x = [str(num) for num, _ in sorted_nums]
        y = [count for _, count in sorted_nums]

        colors = y

        fig = go.Figure(go.Bar(
            x=x,
            y=y,
            marker=dict(
                color=colors,
                colorscale='Viridis',
                showscale=True,
                colorbar=dict(title='Frequenza')
            ),
            text=y,
            textposition='outside',
            hovertemplate='Numero: %{x}<br>Frequenza: %{y}<extra></extra>'
        ))

        # Annotazione valore massimo
        max_idx = y.index(max(y))
        fig.add_annotation(
            x=x[max_idx], y=y[max_idx],
            text="Massima frequenza",
            showarrow=True,
            arrowhead=2,
            ax=0,
            ay=-40
        )

        fig.update_layout(
            title="Frequenza Numeri Totale",
            xaxis_title="Numero",
            yaxis_title="Frequenza",
            xaxis_tickangle=-45,
            margin=dict(l=40, r=40, t=60, b=120),
            plot_bgcolor='white',
            height=500
        )
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
        # Annotazione combinazione più frequente
        max_count = max(counts)
        max_idx = counts.index(max_count)
        fig.add_annotation(
            x=max_count, y=comb_labels[max_idx],
            text="Combinazione più frequente",
            showarrow=True,
            arrowhead=2,
            ax=40,
            ay=0
        )
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
        df_freq['data'] = pd.to_datetime(df_freq['data'])
        fig = px.line(
            df_freq,
            x='data',
            y='freq_cum',
            title=f"Frequenza Cumulativa del Numero {numero} nel Tempo",
            labels={'data': 'Data', 'freq_cum': 'Frequenza cumulativa'},
            markers=True
        )
        fig.update_traces(hovertemplate='Data: %{x|%d-%m-%Y}<br>Frequenza cumulativa: %{y}<extra></extra>')
        fig.update_layout(
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
        return fig

    elif chart_type == 'dist_freq':
        freq = freq_numeri_generate(df)
        counts = list(freq.values())
        fig = px.histogram(
            x=counts,
            nbins=20,
            histnorm='probability density',
            title="Distribuzione Frequenza Numeri",
            labels={'x': 'Frequenza', 'y': 'Densità'},
            opacity=0.75,
            color_discrete_sequence=['teal']
        )
        fig.update_layout(
            bargap=0.1,
            plot_bgcolor='white',
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

    else:
        return go.Figure()

if __name__ == '__main__':
    app.run_server(debug=True)

