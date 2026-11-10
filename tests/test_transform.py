import pandas as pd
import pytest

from app.main import load, run, transform


def sample() -> pd.DataFrame:
    return pd.DataFrame(
        {
            "station_id": [1, 2, 3],
            "name": ["Victoire", "Quinconces", "Gare"],
            "bikes_available": [5, 0, 10],
            "docks_available": [5, 10, 0],
            "lat": [44.83, 44.84, 44.82],
            "lon": [-0.57, -0.57, -0.55],
            "updated_at": ["2026-11-09T08:00:00"] * 3,
        }
    )


def test_transform_computes_fill_rate():
    out = transform(sample())
    assert list(out["fill_rate"]) == [0.5, 0.0, 1.0]


def test_transform_flags_empty_and_full():
    out = transform(sample())
    assert list(out["status"]) == ["ok", "empty", "full"]


def test_transform_drops_stations_without_capacity():
    df = sample()
    df.loc[0, ["bikes_available", "docks_available"]] = 0
    out = transform(df)
    assert len(out) == 2
    assert 1 not in set(out["station_id"])


def test_load_rejects_missing_columns(tmp_path):
    bad = tmp_path / "bad.csv"
    bad.write_text("station_id,name\n1,Victoire\n")
    with pytest.raises(ValueError, match="bikes_available"):
        load(str(bad))


def test_run_writes_parquet(tmp_path):
    src = tmp_path / "stations.csv"
    sample().to_csv(src, index=False)
    out_file = run(str(src), str(tmp_path / "out"))
    assert out_file.endswith("stations.parquet")
    assert len(pd.read_parquet(out_file)) == 3
