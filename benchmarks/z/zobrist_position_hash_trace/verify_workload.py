"""Package-local static fixture/reference comparison entry point; not run."""

import json
from pathlib import Path

from independent_oracle import expected_output as independent_expected
from primary_oracle import expected_output as primary_expected


def check_workload() -> None:
    path = Path(__file__).with_name("workload.json")
    workload = json.loads(path.read_text(encoding="utf-8"))
    if workload.get("algorithm") != "zobrist_position_hash_trace":
        raise ValueError("workload algorithm ID does not match package")
    for case in workload["cases"]:
        values = case["input_values"]
        kwargs = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
        if primary_expected(values, **kwargs) != expected:
            raise ValueError(f"primary reference disagrees on {case['id']}")
        if independent_expected(values, **kwargs) != expected:
            raise ValueError(f"independent reference disagrees on {case['id']}")


if __name__ == "__main__":
    check_workload()
