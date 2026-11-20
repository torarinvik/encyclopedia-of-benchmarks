"""Static contract and oracle review for the 2D Mo workload."""

from __future__ import annotations

import json
from pathlib import Path

from mo_2d_rectangle_frequency_square_oracle import expected_result as primary_result
from mo_2d_rectangle_frequency_square_verifier_oracle import expected_result as independent_result

PACKAGE = Path(__file__).resolve().parent
MAX_VALID_INPUT_LENGTH = 194
MAX_PARSEABLE_INPUT_LENGTH = 195


def verify_workload(workload: dict | None = None) -> None:
    if workload is None:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("algorithm") != "mo_2d_rectangle_frequency_square"
            or workload.get("function_symbol") != "mo_2d_rectangle_frequency_square"
            or workload.get("abi") != "i64_array_scalar"):
        raise ValueError("unexpected 2D Mo workload identity")
    contract = workload.get("input", {})
    if (contract.get("encoding") != "[N,Q,matrix row-major N*N,(top,left,bottom,right)*Q]"
            or contract.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or contract.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH):
        raise ValueError("2D Mo input contract differs from its bounds")
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
            raise ValueError(f"primary 2D Mo fixture mismatch: {case_id}")
        if independent_result(values, **arguments) != expected:
            raise ValueError(f"direct-scan fixture mismatch: {case_id}")

    maximum_values = [8, 32, *([0] * 64), *([0, 0, 7, 7] * 32)]
    if len(maximum_values) != MAX_VALID_INPUT_LENGTH:
        raise ValueError("maximum 2D Mo frame construction mismatch")
    if (primary_result(maximum_values) != 2_162_688
            or independent_result(maximum_values) != 2_162_688):
        raise ValueError("maximum all-equal matrix checksum mismatch")
    if (primary_result((*maximum_values, 0)) != -1
            or independent_result((*maximum_values, 0)) != -1):
        raise ValueError("maximum parseable trailing word was accepted")


if __name__ == "__main__":
    verify_workload()
