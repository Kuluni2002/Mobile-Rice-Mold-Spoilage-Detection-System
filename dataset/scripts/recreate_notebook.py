import json, os
path = r"d:\Research\Mobile-Rice-Mold-Spoilage-Detection-System\dataset\scripts\recategorize_dataset.ipynb"
nb = {
  "cells": [
    {"cell_type":"code","metadata":{},"source":["import sys\n","print(sys.executable)\n"],"outputs":[],"execution_count":None}
  ],
  "metadata": {},
  "nbformat": 4,
  "nbformat_minor": 5
}
os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, "w", encoding="utf-8") as f:
    json.dump(nb, f, indent=1, ensure_ascii=False)
print("Wrote", path)