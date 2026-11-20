"""Static fixture check for both Störmer-Verlet references; not run in this task."""

from __future__ import annotations

import json
import sys
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
REPOSITORY = PACKAGE.parents[2]
sys.path.insert(0, str(PACKAGE))
sys.path.insert(0, str(REPOSITORY / "benchmarks"))

from independent_oracle import expected_output as independent_expected_output
from stormer_verlet_position_oracle import expected_output as primary_expected_output


def validate_workload() -> None:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if workload.get("algorithm") != "stormer_verlet_position":
        raise ValueError("workload algorithm id does not match the package")
    for case in workload.get("cases", []):
        values = case.get("input_values")
        result = case.get("expected_result")
        expected = bytes.fromhex(case.get("expected_output_hex", ""))
        capacity = case.get("output_capacity")
        input_length = case.get("input_length")
        primary = primary_expected_output(values, capacity=capacity, input_length=input_length)
        independent = independent_expected_output(values, capacity=capacity, input_length=input_length)
        if primary != independent or primary != (result, expected):
            raise ValueError(f"fixture mismatch: {case.get('id')}")


if __name__ == "__main__":
    validate_workload()
