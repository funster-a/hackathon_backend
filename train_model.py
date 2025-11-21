"""
Utility script that trains a simple keyword-based expense classifier.

The model is saved as JSON so it can be loaded without external ML libraries.
"""

import csv
import json
import math
import re
from collections import Counter, defaultdict
from pathlib import Path
from typing import Dict, List

ROOT = Path(__file__).parent
DATA_PATH = ROOT / "data" / "sample_transactions.csv"
MODEL_PATH = ROOT / "models" / "expense_classifier.json"
TOKEN_PATTERN = re.compile(r"[A-Za-zА-Яа-яЁё]+")


def tokenize(text: str) -> List[str]:
    return TOKEN_PATTERN.findall(text.lower())


def train() -> None:
    category_counts: Counter[str] = Counter()
    token_counts: Dict[str, Counter[str]] = defaultdict(Counter)

    with DATA_PATH.open("r", encoding="utf-8") as csv_file:
        reader = csv.DictReader(csv_file)
        for row in reader:
            amount = float(row["amount"])
            if amount >= 0:
                continue  # skip пополнения

            category = row["category"]
            category_counts[category] += 1

            tokens = tokenize(row["description"])
            token_counts[category].update(tokens)

    total_docs = sum(category_counts.values())
    vocab = set()
    for counter in token_counts.values():
        vocab.update(counter.keys())

    model = {
        "category_priors": {
            category: count / total_docs for category, count in category_counts.items()
        },
        "token_likelihoods": {
            category: {
                token: (count + 1)
                / (sum(counter.values()) + len(vocab))
                for token, count in counter.items()
            }
            for category, counter in token_counts.items()
        },
        "default_likelihood": {
            category: 1 / (sum(counter.values()) + len(vocab))
            for category, counter in token_counts.items()
        },
        "vocabulary": list(vocab),
    }

    MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)
    with MODEL_PATH.open("w", encoding="utf-8") as f:
        json.dump(model, f, ensure_ascii=False, indent=2)

    print(f"Model trained on {total_docs} расходных операций.")
    print(f"Vocabulary size: {len(vocab)} токенов.")
    print(f"Model saved to {MODEL_PATH}")


if __name__ == "__main__":
    train()

