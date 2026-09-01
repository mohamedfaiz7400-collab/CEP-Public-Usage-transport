"""
CEP: Public Transport & Optimization Analysis
Data Generator - Creates synthetic 500k bus dataset if CSV not available
Run: python data_generator.py
"""
import pandas as pd
import numpy as np
from pathlib import Path

OUT = Path(__file__).parent / "data" / "bus_data.csv"

def random_dates(n):
    start = pd.to_datetime("2015-01-01")
    end = pd.to_datetime("2024-12-31")
    return pd.to_datetime(np.random.randint(start.value//10**9, end.value//10**9, n), unit='s').date

def generate(n=500_000, out_path=OUT):
    out_path = Path(out_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    np.random.seed(42)
    agencies = ["RedBus", "VRL Travels", "SRS Travels", "Parveen Travels", "Orange Tours", "KPN Travels", "Chartered Speed"]
    sources = ["Delhi", "Mumbai", "Kolkata", "Chennai", "Hyderabad", "Pune", "Jaipur", "Ahmedabad", "Lucknow", "Bangalore"]
    destinations = ["Delhi", "Mumbai", "Kolkata", "Chennai", "Hyderabad", "Pune", "Jaipur", "Ahmedabad", "Lucknow", "Bangalore"]
    bus_types = ["AC Sleeper", "Non-AC Sleeper", "Volvo", "AC Seater", "Non-AC Seater", "AC Semi-Sleeper"]

    df = pd.DataFrame({
        "Agency": np.random.choice(agencies, n, p=[0.35,0.15,0.15,0.12,0.08,0.08,0.07]),
        "Source": np.random.choice(sources, n),
        "Destination": np.random.choice(destinations, n),
        "Bus Type": np.random.choice(bus_types, n, p=[0.25,0.2,0.2,0.15,0.1,0.1]),
        "Travel Date": random_dates(n),
        "Fare Price (INR)": np.round(np.random.normal(1500, 600, n).clip(400, 3500), 2),
        "Total Seats": np.random.choice([28,30,32,38,40,45,50], n, p=[0.1,0.1,0.15,0.2,0.2,0.15,0.1]),
        "Duration (hours)": np.round(np.random.normal(12, 4, n).clip(3, 24), 1)
    })
    mask = df["Source"] == df["Destination"]
    while mask.any():
        df.loc[mask, "Destination"] = np.random.choice(destinations, mask.sum())
        mask = df["Source"] == df["Destination"]
    df.loc[df["Bus Type"].isin(["AC Sleeper","Volvo"]), "Fare Price (INR)"] += np.random.randint(200,600, (df["Bus Type"].isin(["AC Sleeper","Volvo"])).sum())
    df["Fare Price (INR)"] = df["Fare Price (INR)"] + df["Duration (hours)"]*45
    df["Fare Price (INR)"] = df["Fare Price (INR)"].round(2).clip(350, 4000)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(out_path, index=False)
    print(f"Generated {len(df)} rows at {out_path}")
    return df

if __name__ == "__main__":
    generate()
