"""
CEP Public Transport - ML Prediction Models
VS Code: python models/ml_models.py
Predicts: Fare Price (INR) & Duration optimization
Models: Linear Regression, Random Forest, XGBoost, LightGBM
"""
import pandas as pd
import numpy as np
from pathlib import Path
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.linear_model import LinearRegression
from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor
from sklearn.metrics import r2_score, mean_absolute_error, mean_squared_error
import pickle, json

DATA_PATH = Path(__file__).parent.parent / "data" / "bus_data.csv"
# Fallback: try to find CSV in common locations
if not DATA_PATH.exists():
    for p in [Path(r"C:\Users\ashiy\OneDrive\Documents\Default Project\data.csv"), Path("bus_data.csv")]:
        if p.exists():
            DATA_PATH = p
            break

def load_data(sample=100000):
    """Load and sample for fast training (use full 500k for final)"""
    df = pd.read_csv(DATA_PATH)
    if len(df) > sample:
        df = df.sample(sample, random_state=42)
    df["Travel Date"] = pd.to_datetime(df["Travel Date"])
    df["Year"] = df["Travel Date"].dt.year
    df["Month"] = df["Travel Date"].dt.month
    df["DayOfWeek"] = df["Travel Date"].dt.dayofweek
    df["Route"] = df["Source"] + " -> " + df["Destination"]
    # Target engineering
    df["Fare_per_hour"] = df["Fare Price (INR)"] / df["Duration (hours)"]
    return df

def train_fare_model(df):
    cat = ["Agency", "Source", "Destination", "Bus Type"]
    num = ["Total Seats", "Duration (hours)", "Year", "Month", "DayOfWeek"]
    X = df[cat + num]
    y = df["Fare Price (INR)"]

    pre = ColumnTransformer([
        ("cat", OneHotEncoder(handle_unknown="ignore", sparse_output=False), cat),
        ("num", StandardScaler(), num)
    ])

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    models = {
        "LinearRegression": LinearRegression(),
        "RandomForest": RandomForestRegressor(n_estimators=100, n_jobs=-1, random_state=42),
        "GradBoost": GradientBoostingRegressor(random_state=42),
    }
    # Optional XGBoost/LightGBM if installed
    try:
        from xgboost import XGBRegressor
        models["XGBoost"] = XGBRegressor(n_estimators=100, n_jobs=-1, random_state=42, verbosity=0)
    except: pass
    try:
        from lightgbm import LGBMRegressor
        models["LightGBM"] = LGBMRegressor(n_estimators=100, verbose=-1, random_state=42)
    except: pass

    results = []
    best = None
    best_r2 = -1
    for name, model in models.items():
        pipe = Pipeline([("pre", pre), ("model", model)])
        pipe.fit(X_train, y_train)
        pred = pipe.predict(X_test)
        r2 = r2_score(y_test, pred)
        mae = mean_absolute_error(y_test, pred)
        rmse = np.sqrt(mean_squared_error(y_test, pred))
        results.append({"Model": name, "R2": round(r2,4), "MAE": round(mae,2), "RMSE": round(rmse,2)})
        print(f"{name:15} R2={r2:.4f} MAE={mae:.2f} RMSE={rmse:.2f}")
        if r2 > best_r2:
            best_r2 = r2
            best = (name, pipe)

    results_df = pd.DataFrame(results).sort_values("R2", ascending=False)
    print("\n", results_df.to_string(index=False))

    # Save best
    out = Path(__file__).parent / "fare_model.pkl"
    with open(out, "wb") as f:
        pickle.dump(best[1], f)
    print(f"Saved best model ({best[0]}) to {out}")
    results_df.to_csv(Path(__file__).parent / "model_comparison.csv", index=False)
    return results_df, best[1]

# Optimization: Linear Programming for Fleet Allocation
def fleet_optimization_example():
    """
    Simple LP: Maximize profit given bus allocation constraints
    Use pulp (pip install pulp)
    """
    try:
        import pulp
    except:
        print("Install pulp: pip install pulp")
        return

    # Example: 3 routes, 2 bus types, profit per trip
    routes = ["Delhi-Chennai", "Kolkata-Delhi", "Pune-Jaipur"]
    profit = {
        ("Delhi-Chennai", "Volvo"): 18000,
        ("Delhi-Chennai", "AC Sleeper"): 15000,
        ("Kolkata-Delhi", "Volvo"): 22000,
        ("Kolkata-Delhi", "AC Sleeper"): 19000,
        ("Pune-Jaipur", "Volvo"): 14000,
        ("Pune-Jaipur", "AC Sleeper"): 12000,
    }
    # Limited fleet: 20 Volvo, 25 AC Sleeper
    prob = pulp.LpProblem("Fleet_Max_Profit", pulp.LpMaximize)
    x = pulp.LpVariable.dicts("trips", profit.keys(), lowBound=0, cat="Integer")
    prob += pulp.lpSum([profit[k]*x[k] for k in profit])
    prob += pulp.lpSum([x[k] for k in profit if k[1]=="Volvo"]) <= 20
    prob += pulp.lpSum([x[k] for k in profit if k[1]=="AC Sleeper"]) <= 25
    prob.solve(pulp.PULP_CBC_CMD(msg=0))
    print(f"Status: {pulp.LpStatus[prob.status]} Profit: {pulp.value(prob.objective)}")
    for k in profit:
        print(k, x[k].value())

if __name__ == "__main__":
    print(f"Loading {DATA_PATH}")
    # If no CSV, generate synthetic
    if not DATA_PATH.exists():
        print("CSV not found, generating synthetic 100k sample...")
        import sys
        sys.path.append(str(Path(__file__).parent.parent))
        from data_generator import df if False else None
        # fallback generate
        exec(open(Path(__file__).parent.parent / "data_generator.py").read())

    df = load_data(sample=80000)
    print(df.head())
    train_fare_model(df)
    print("\n--- Fleet LP Demo ---")
    fleet_optimization_example()
