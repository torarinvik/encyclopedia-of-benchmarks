"""Static fixture/oracle review for Dinkelbach ratio selection."""

from __future__ import annotations

import json
from pathlib import Path

from dinkelbach_fixed_cardinality_ratio_oracle import expected_result as primary_result
from dinkelbach_fixed_cardinality_ratio_verifier_oracle import expected_result as independent_result

PACKAGE = Path(__file__).resolve().parent
MAX_VALID_INPUT_LENGTH = 26
MAX_PARSEABLE_INPUT_LENGTH = 27


def verify_workload(workload: dict | None = None) -> None:
    if workload is None:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("algorithm") != "dinkelbach_fixed_cardinality_ratio"
            or workload.get("function_symbol") != "dinkelbach_fixed_cardinality_ratio"
            or workload.get("abi") != "i64_array_scalar"):
        raise ValueError("unexpected Dinkelbach workload identity")
    contract = workload.get("input", {})
    if (contract.get("encoding") != "[N,K,(numerator,denominator)*N]"
            or contract.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or contract.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH):
        raise ValueError("Dinkelbach workload contract differs from its bounds")
    for case in workload.get("cases", []):
        values = case.get("input_values")
        case_id = case.get("id", "<unnamed>")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            raise ValueError(f"fixture input length mismatch: {case_id}")
        arguments = {
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = case.get("expected_result")
        if primary_result(values, **arguments) != expected:
            raise ValueError(f"Dinkelbach iteration fixture mismatch: {case_id}")
        if independent_result(values, **arguments) != expected:
            raise ValueError(f"exhaustive ratio fixture mismatch: {case_id}")

    maximum_values = (12, 6, *((value for _ in range(12) for value in (10_000, 1))))
    if len(maximum_values) != MAX_VALID_INPUT_LENGTH:
        raise ValueError("maximum Dinkelbach frame construction mismatch")
    if (primary_result(maximum_values) != 1_200_010_001
            or independent_result(maximum_values) != 1_200_010_001):
        raise ValueError("maximum equal-ratio checksum mismatch")
    if (primary_result((*maximum_values, 0)) != -1
            or independent_result((*maximum_values, 0)) != -1):
        raise ValueError("maximum parseable trailing word was accepted")


if __name__ == "__main__":
    verify_workload()
