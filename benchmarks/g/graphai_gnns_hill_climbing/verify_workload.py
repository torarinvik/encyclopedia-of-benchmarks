"""Review fixtures against independent GNNS profile oracles."""

from __future__ import annotations

import json
from pathlib import Path

from graphai_gnns_hill_climbing_oracle import expected_result as primary_result
from graphai_gnns_hill_climbing_verifier_oracle import expected_result as independent_result

ROOT = Path(__file__).resolve().parents[3]
WORKLOAD = ROOT / "benchmarks/g/graphai_gnns_hill_climbing/workload.json"


def verify_workload(workload: dict) -> None:
    if workload != json.loads(WORKLOAD.read_text(encoding="utf-8")):
        raise ValueError("graphai_gnns_hill_climbing workload differs from its package file")
    for fixture in workload.get("cases", []):
        values = fixture.get("input_values")
        if not isinstance(values, list) or fixture.get("input_length") != len(values):
            raise ValueError(f"GNNS fixture framing is invalid: {fixture.get('id')}")
        arguments = {
            "input_is_null": fixture.get("input_is_null", False),
            "input_length": fixture.get("input_length"),
        }
        expected = fixture.get("expected_result")
        if primary_result(values, **arguments) != expected:
            raise ValueError(f"GNNS mask-oracle fixture mismatch: {fixture.get('id')}")
        if independent_result(values, **arguments) != expected:
            raise ValueError(f"GNNS list-oracle fixture mismatch: {fixture.get('id')}")
