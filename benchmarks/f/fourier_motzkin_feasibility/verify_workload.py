"""Static workload validator for Fourier–Motzkin feasibility."""

from __future__ import annotations

import json
from pathlib import Path

from fourier_motzkin_feasibility_oracle import expected_result


def verify_workload(workload: dict) -> None:
    expected = json.loads((Path(__file__).with_name("workload.json")).read_text(encoding="utf-8"))
    if workload != expected:
        raise ValueError("Fourier–Motzkin workload differs from its package file")
    for case in workload.get("cases", []):
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            raise ValueError(f"invalid input framing for {case.get('id', '<unnamed>')}")
        result = expected_result(values, input_is_null=case.get("input_is_null", False),
                                 input_length=case.get("input_length"))
        if result != case.get("expected_result"):
            raise ValueError(f"oracle result mismatch for {case.get('id', '<unnamed>')}")
