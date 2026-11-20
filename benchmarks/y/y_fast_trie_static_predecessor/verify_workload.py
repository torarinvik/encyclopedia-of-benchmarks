"""Fixture review for the bounded y-fast trie predecessor/successor profile."""

from __future__ import annotations

import json
from pathlib import Path

from y_fast_trie_static_predecessor_oracle import expected_result as primary_result
from y_fast_trie_static_predecessor_verifier_oracle import expected_result as independent_result

ROOT = Path(__file__).resolve().parents[3]
WORKLOAD = ROOT / "benchmarks/y/y_fast_trie_static_predecessor/workload.json"


def verify_workload(workload: dict) -> None:
    if workload != json.loads(WORKLOAD.read_text(encoding="utf-8")):
        raise ValueError("y_fast_trie_static_predecessor workload differs from its package file")
    for fixture in workload.get("cases", []):
        values = fixture.get("input_values")
        if not isinstance(values, list) or fixture.get("input_length") != len(values):
            raise ValueError(f"y-fast fixture framing is invalid: {fixture.get('id')}")
        arguments = {
            "input_is_null": fixture.get("input_is_null", False),
            "input_length": fixture.get("input_length"),
        }
        expected = fixture.get("expected_result")
        if primary_result(values, **arguments) != expected:
            raise ValueError(f"y-fast primary oracle fixture mismatch: {fixture.get('id')}")
        if independent_result(values, **arguments) != expected:
            raise ValueError(f"y-fast independent oracle fixture mismatch: {fixture.get('id')}")
