"""Job de données : stations de vélos -> taux de remplissage -> Parquet."""

import os
from pathlib import Path

import pandas as pd

REQUIRED_COLUMNS = [
    "station_id",
    "name",
    "bikes_available",
    "docks_available",
    "lat",
    "lon",
    "updated_at",
]


def load(source: str) -> pd.DataFrame:
    df = pd.read_csv(source)
    missing = [c for c in REQUIRED_COLUMNS if c not in df.columns]
    if missing:
        raise ValueError(f"Colonnes manquantes : {', '.join(missing)}")
    return df[REQUIRED_COLUMNS]


def transform(df: pd.DataFrame) -> pd.DataFrame:
    capacity = df["bikes_available"] + df["docks_available"]
    out = df[capacity > 0].copy()
    out["fill_rate"] = (out["bikes_available"] / capacity[capacity > 0]).round(2)
    out["status"] = "ok"
    out.loc[out["bikes_available"] == 0, "status"] = "empty"
    out.loc[out["docks_available"] == 0, "status"] = "full"
    return out


def run(source: str, output_dir: str) -> str:
    out_dir = Path(output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / "stations.parquet"
    transform(load(source)).to_parquet(out_file, index=False)
    return str(out_file)


def main() -> None:
    source = os.environ.get("SOURCE_URL", "data/stations.csv")
    output_dir = os.environ.get("OUTPUT_DIR", "output")
    out_file = run(source, output_dir)
    print(f"Écrit : {out_file}")


if __name__ == "__main__":
    main()
