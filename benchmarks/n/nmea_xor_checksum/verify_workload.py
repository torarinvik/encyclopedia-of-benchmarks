"""Static fixture and contract checks for the NMEA XOR checksum workload."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent_result
from .primary_oracle import (
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    expected_result as primary_result,
)

PACKAGE = Path(__file__).resolve().parent
WORKLOAD_PATH = PACKAGE / "workload.json"


def workload_issues(workload: dict | None = None) -> list[str]:
    issues: list[str] = []
    if workload is None:
        try:
            workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    if (workload.get("algorithm") != "nmea_xor_checksum"
            or workload.get("function_symbol") != "nmea_xor_checksum"
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("workload identity or ABI is incorrect")
    input_spec = workload.get("input", {})
    if (input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_spec.get("payload_length_range") != [0, 76]
            or input_spec.get("payload_byte_range") != [0, 127]):
        issues.append("workload input bounds differ from the package contract")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload has no fixture cases"]
    for case in cases:
        name = case.get("id", "<unnamed>")
        values = case.get("input_values")
        length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        expected = case.get("expected_result")
        if (not isinstance(values, list) or type(length) is not int
                or type(is_null) is not bool or length != len(values)
                or length > MAX_PARSEABLE_INPUT_LENGTH
                or (is_null and values)):
            issues.append(f"fixture framing is invalid: {name}")
            continue
        primary = primary_result(values, input_is_null=is_null, input_length=length)
        independent = independent_result(values, input_is_null=is_null, input_length=length)
        if type(expected) is not int or expected != primary or primary != independent:
            issues.append(f"fixture references disagree: {name}")
    return issues
