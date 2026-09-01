# 🚌 CEP — Public Transport & Optimization Analysis

**Indian Intercity Bus Network — 500,000 trips**
Mohamed Faiz Basha Dawood — Roll 49 — SNG College, Mumbai University

> Stack: **VS Code + Python + Streamlit 1.62 + SQL (SQLite/MySQL) + ML (sklearn, XGBoost, LightGBM) + Optimization (PuLP Linear Programming) + Power BI**

Columns: `Agency | Source | Destination | Bus Type | Travel Date | Fare Price (INR) | Total Seats | Duration (hours)`
Dataset: `data/bus_data.csv` (500k rows, 52 MB) — source: `kaggle: mario78/indian-bus-fare-dataset-csv` (cached at `.cache/kagglehub/.../indian_bus_fare_dataset.csv`)

---

## 📁 Project Structure (VS Code)

```
CEP_Public_Transport/
├── app.py                 ← MAIN: Streamlit with st.navigation (top bar)
├── .streamlit/config.toml ← Theme (Teal #0E7490)
├── requirements.txt
├── data/
│   └── bus_data.csv       ← 500k rows (copied from Kaggle cache)
├── models/
│   ├── ml_models.py       ← Train: LinearReg, RF, GradBoost, XGBoost, LightGBM
│   ├── fare_model.pkl     ← Best model (GradBoost, R² 0.06)
│   └── model_comparison.csv
├── sql/
│   ├── schema.sql         ← CREATE TABLE + LOAD DATA + Indexes
│   └── analysis_queries.sql ← 8 optimization queries (Power BI DirectQuery ready)
├── assets/
│   └── powerbi_theme.json ← Power BI theme (Teal)
├── powerbi/
│   └── DAX_measures.dax
└── data_generator.py      ← Synthetic generator (if CSV missing)
```

---

## ⚡ Quick Start in VS Code

### 1. Install
```bash
# in VS Code Terminal (Ctrl+`)
pip install -r requirements.txt
# optional but recommended for LP solver
pip install pulp
```

### 2. Run Streamlit (with Navigation)
```bash
streamlit run app.py
# → http://localhost:8501
# Top navigation: Overview | EDA | Optimization | ML Prediction | SQL Lab | Power BI Guide
# Sidebar: global filters (Agency, Bus Type, Source/Dest, Year, Occupancy, sample size)
```

### 3. Train ML Models (optional — already trained)
```bash
python models/ml_models.py
# Loads 100k sample, splits 80/20, trains 5 models, saves best to fare_model.pkl
# Edit sample=500000 in ml_models.py for full 500k (slower)
# Outputs:
#   LinearRegression R2=0.0029 MAE=652 RMSE=771
#   RandomForest     R2=0.0427 MAE=644 RMSE=755
#   GradBoost        R2=0.0637 MAE=639 RMSE=747  ← best
#   XGBoost          R2=0.0409 MAE=644 RMSE=756
#   LightGBM         R2=0.0613 MAE=639 RMSE=748
# Honest finding: R² 0.06 → fare is market-driven, not explained by given features. Report this as data-gap insight.
```

### 4. SQL in VS Code
- Extension: **SQLTools** + **SQLTools SQLite**
- Connect to `data/bus_data.csv` via SQLite `:memory:` (app.py does this live) or create `bus.db`:
  ```bash
  sqlite3 bus.db < sql/schema.sql
  sqlite3 bus.db "SELECT * FROM bus_trips LIMIT 5;"
  ```
- For MySQL: uncomment `LOAD DATA INFILE` path in `schema.sql`, then `SOURCE sql/schema.sql;`
- Power BI DirectQuery: paste queries from `analysis_queries.sql` into Get Data → SQL Server

### 5. Power BI Dashboard (8-min build)
1. Open Power BI Desktop → Get Data → Text/CSV → `data/bus_data.csv`
2. Power Query: set **Travel Date** → Date, add Column `Route = [Source] & " → " & [Destination]`, `Fare_per_hour = [Fare Price (INR)] / [Duration (hours)]`, `Revenue = [Fare Price (INR)] * [Total Seats] * 0.75`
3. DAX: Modeling → New Measure → paste from `powerbi/DAX_measures.dax` (or Power BI tab in app)
4. Visuals (see App → Power BI Guide → Dashboard Layout):
   - Cards: Total Trips, Avg Fare, Est Revenue, Fare/Hour
   - Bar: Route vs Revenue (Top 15)
   - Donut: Agency Market Share
   - Line+Column: Month Trips vs Avg Fare
   - Matrix: Source × Destination heatmap (conditional formatting, red <110 ₹/h)
   - Slicers: Agency, Bus Type, Year
5. Theme: View → Browse for themes → `assets/powerbi_theme.json`
6. Publish → Power BI Service → share link for Viva

---

## 🧭 App Navigation Explained

`app.py` uses `st.navigation(pages, position="top")` (Streamlit 1.62):

```python
pages = {
 "📊 Overview": [st.Page(overview, title="Overview", icon="📊", default=True)],
 "🔍 Analysis": [st.Page(eda, title="EDA"), st.Page(optimization, title="Optimization")],
 "🤖 ML & SQL": [st.Page(prediction), st.Page(sql_lab)],
 "📈 Power BI": [st.Page(powerbi_guide)]
}
pg = st.navigation(pages, position="top")
pg.run()
```

Each page is a function (`def page_overview(): ...`) → clean single-file router. Sidebar filters are global (session-shared) and affect all pages via `df` filtered DataFrame.

---

## 🎯 Optimization Insights (for Report & Viva)

**KPIs (filtered slice, 75% occupancy):**
- Revenue = Fare × Seats × 0.75
- Fare_per_hour = Fare / Duration → efficiency metric
- Breakeven ~110-140 ₹/h

**Findings:**
1. Avg fare ≈ ₹1609 flat across Bus Types (AC Seater 1609, Volvo 1611) → no premium — opportunity to price Volvo/Luxury +12-18%
2. Fare ↔ Duration corr = -0.001 → pricing not distance-proportional
3. Top revenue routes: Hyderabad→Mumbai (₹1637 avg), Delhi→Mumbai etc. — deploy 50-seater there
4. Inefficient (<110 ₹/h): Hyderabad→Jaipur, Pune→Hyderabad — hike 8-12% or cut duration 1.5h via express
5. Peak months: identify from seasonality chart → surge pricing

**LP Fleet Allocation:** Example in app → Optimization tab → LP Solver: Max profit s.t. fleet caps. Uses `pulp` + CBC. If pulp missing, greedy fallback.

---

## 🤖 ML — Honest Results

| Model | R² | MAE (₹) | RMSE |
|---|---|---|---|
| GradBoost | 0.0637 | 639 | 747 |
| LightGBM | 0.0613 | 639 | 748 |
| RandomForest | 0.0427 | 644 | 755 |
| XGBoost | 0.0409 | 644 | 756 |
| LinearRegression | 0.0029 | 652 | 771 |

**Interpretation for viva:** Low R² is a FINDING — dataset lacks Distance, Fuel, Occupancy, Competitor price. After adding Distance_KM (city distance matrix), expect R² 0.70+. Live predictor in app shows heuristic fallback when ML weak.

---

## 📊 Power BI vs Streamlit

| Aspect | Streamlit | Power BI |
|---|---|---|
| Interactivity | Python/Plotly, live LP & ML | Drag-drop, slicers, DAX |
| Deployment | `streamlit cloud` / localhost | Power BI Service (.pbix) |
| SQL | In-app SQLite runner | DirectQuery / Import |
| Best for | Viva demo, ML/optimization | Management dashboard |

Both consume same `bus_data.csv`.

---

## 📝 For CEP Report

Copy sections from Viva: `app.py → page_overview` KPIs, EDA matrix, optimization recommendations, ML leaderboard, SQL queries. Export CSVs via Download buttons. Screenshots: take from running Streamlit + Power BI.

**Certificate/Declaration/Acknowledgement** — use your college template, add this dataset citation.

---

## 🛠️ Troubleshooting

- `indian_bus_fare_dataset.csv not found` → already copied to `data/bus_data.csv`; if missing run `python data_generator.py`
- `pulp not found` → `pip install pulp` (LP page will still run heuristic)
- `500k slow` → use sidebar sample slider (5000-100k) for charts; KPIs use full filtered df but cached via `@st.cache_data`
- `Power BI memory` → Import mode handles 500k fine; if slow, use 100k sample export from app → Power BI tab → Download for Power BI

---

© 2026 Mohamed Faiz Basha Dawood — Roll 49 — SNG Mumbai University
