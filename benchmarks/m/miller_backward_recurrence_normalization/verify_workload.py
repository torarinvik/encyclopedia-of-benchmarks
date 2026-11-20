"""Static workload/reference reconciliation API; intentionally not run here."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import (
        MAX_OUTPUT_BYTES as INDEPENDENT_MAX_OUTPUT,
        MAX_PARSEABLE_INPUT_LENGTH as INDEPENDENT_MAX_INPUT,
        WORKSPACE_BYTES as INDEPENDENT_WORKSPACE,
        expected_output as independent_output,
    )
    from .primary_oracle import (
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        MODULUS,
        WORKSPACE_BYTES,
        expected_output,
    )
except ImportError:
    from independent_oracle import (
        MAX_OUTPUT_BYTES as INDEPENDENT_MAX_OUTPUT,
        MAX_PARSEABLE_INPUT_LENGTH as INDEPENDENT_MAX_INPUT,
        WORKSPACE_BYTES as INDEPENDENT_WORKSPACE,
        expected_output as independent_output,
    )
    from primary_oracle import (
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        MODULUS,
        WORKSPACE_BYTES,
        expected_output,
    )

PACKAGE = Path(__file__).resolve().parent
SOURCE_URL = "https://dlmf.nist.gov/3.6.iii"


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if (workload.get("algorithm") != "miller_backward_recurrence_normalization"
            or workload.get("function_symbol") != "miller_backward_recurrence_normalization"
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("source", {}).get("url") != SOURCE_URL):
        issues.append("workload identity or DLMF source differs")
    if (workload.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("input", {}).get("coefficient_range") != [0, MODULUS - 1]
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES
            or (INDEPENDENT_MAX_INPUT, INDEPENDENT_MAX_OUTPUT, INDEPENDENT_WORKSPACE)
            != (MAX_PARSEABLE_INPUT_LENGTH, MAX_OUTPUT_BYTES, WORKSPACE_BYTES)):
        issues.append("workload bounds or workspace differ from references")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases are missing"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("fixture is not a named object")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture ID: {case_id}")
            continue
        seen.add(case_id)
        values = case.get("input_values")
        if not isinstance(values, list):
            issues.append(f"fixture input is not a list: {case_id}")
            continue
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        if type(input_is_null) is not bool or type(output_is_null) is not bool:
            issues.append(f"fixture null flag is not boolean: {case_id}")
            continue
        input_length = case.get("input_length")
        if type(input_length) is not int:
            issues.append(f"fixture input length is missing or invalid: {case_id}")
            continue
        if (input_is_null and (values or input_length != 0)
                or not input_is_null and input_length != len(values)):
            issues.append(f"fixture input framing differs: {case_id}")
        kwargs = {
            "capacity": case.get("output_capacity"),
            "output_is_null": output_is_null,
            "input_is_null": input_is_null,
            "input_length": input_length,
        }
        try:
            primary = expected_output(values, **kwargs)
            independent = independent_output(values, **kwargs)
        except (ArithmeticError, OverflowError, TypeError, ValueError) as error:
            issues.append(f"oracle could not classify {case_id}: {error}")
            continue
        try:
            expected_bytes = bytes.fromhex(case.get("expected_output_hex"))
        except (TypeError, ValueError):
            issues.append(f"fixture output is not valid hex: {case_id}")
            continue
        pinned = (case.get("expected_result"), expected_bytes)
        if primary != pinned:
            issues.append(f"fixture differs from backward-trial oracle: {case_id}")
        if independent != primary:
            issues.append(f"boundary-system oracle disagrees: {case_id}")
    maximum = next((case for case in cases if isinstance(case, dict)
                    and case.get("id") == "maximum-valid-frame"), None)
    if (maximum is None or maximum.get("input_length") != MAX_VALID_INPUT_LENGTH
            or maximum.get("expected_result") != MAX_OUTPUT_BYTES):
        issues.append("maximum valid input/output fixture is missing")
    if not any(isinstance(case, dict) and case.get("id") == "maximum-output-one-byte-short"
               and case.get("output_capacity") == MAX_OUTPUT_BYTES - 1
               and case.get("expected_result") == -2 for case in cases):
        issues.append("maximum-output one-byte-short fixture is missing")
    if not any(isinstance(case, dict) and case.get("input_length") == MAX_PARSEABLE_INPUT_LENGTH
               and case.get("expected_result") == -1 for case in cases):
        issues.append("maximum parseable malformed-frame fixture is missing")
    return issues


def verify_workload() -> int:
    issues = workload_issues()
    if issues:
        raise ValueError("\n".join(issues))
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    return len(workload["cases"])


if __name__ == "__main__":
    print(f"{verify_workload()} fixtures reconciled")
