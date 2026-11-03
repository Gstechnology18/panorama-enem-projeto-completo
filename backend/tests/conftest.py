import os
from pathlib import Path

os.environ["PANORAMA_DATA_MODE"] = "demo"
os.environ["PANORAMA_DEMO_CSV"] = str(
    Path(__file__).resolve().parents[1] / "data" / "demo" / "enem_demo.csv"
)
