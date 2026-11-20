"""Static workload/reference consistency helper; intentionally not run."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import (
        MAX_OUTPUT_BYTES as INDEPENDENT_MAX_OUTPUT,
        MAX_PARSEABLE_INPUT_LENGTH as INDEPENDENT_MAX_INPUT,
        expected_output as independent_output,
    )
    from .primary_oracle import (
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        WORKSPACE_BYTES,
        expected_output,
    )
except ImportError:  # direct package-local import
    from independent_oracle import (
        MAX_OUTPUT_BYTES as INDEPENDENT_MAX_OUTPUT,
        MAX_PARSEABLE_INPUT_LENGTH as INDEPENDENT_MAX_INPUT,
        expected_output as independent_output,
    )
    from primary_oracle import (
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        WORKSPACE_BYTES,
        expected_output,
    )

PACKAGE = Path(__file__).resolve().parent
SOURCE_URL = "https://dlmf.nist.gov/3.10.iii"


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if (workload.get("algorithm") != "lentz_continued_fraction_convergents"
            or workload.get("function_symbol") != "lentz_continued_fraction_convergents"
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("source", {}).get("url") != SOURCE_URL):
        issues.append("workload identity, ABI, or source differs")
    if (workload.get("input", {}).get("encoding") != "[N,b0,a1,b1,...,aN,bN]"
            or workload.get("input", {}).get("term_count_range") != [1, 8]
            or workload.get("output", {}).get("encoding")
            != "[N+1,h0,h1,...,hN] over F_998244353"):
        issues.append("workload input/output encoding differs from the package contract")
    if (workload.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES
            or (INDEPENDENT_MAX_INPUT, INDEPENDENT_MAX_OUTPUT)
            != (MAX_PARSEABLE_INPUT_LENGTH, MAX_OUTPUT_BYTES)):
        issues.append("workload/reference bounds or native workspace differ")

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
        if case.get("input_length") != len(values):
            issues.append(f"fixture input_length mismatch: {case_id}")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        if type(input_is_null) is not bool or type(output_is_null) is not bool:
            issues.append(f"fixture null flag is not boolean: {case_id}")
        if input_is_null and (values or case.get("input_length") != 0):
            issues.append(f"null input fixture has a nonempty frame: {case_id}")
        if not input_is_null and not values:
            issues.append(f"non-null input fixture has an empty frame: {case_id}")
        capacity = case.get("output_capacity")
        if type(capacity) is not int or capacity < 0:
            issues.append(f"fixture output capacity is invalid: {case_id}")
        kwargs = {
            "capacity": capacity,
            "output_is_null": output_is_null,
            "input_is_null": input_is_null,
            "input_length": case.get("input_length"),
        }
        try:
            primary = expected_output(values, **kwargs)
            independent = independent_output(values, **kwargs)
        except (ArithmeticError, OverflowError, TypeError, ValueError) as error:
            issues.append(f"oracle could not classify {case_id}: {error}")
            continue
        try:
            expected_bytes = bytes.fromhex(case.get("expected_output_hex", ""))
        except (TypeError, ValueError):
            issues.append(f"fixture output is not valid hex: {case_id}")
            continue
        if (primary[0] != case.get("expected_result") or primary[1] != expected_bytes):
            issues.append(f"fixture differs from Lentz oracle: {case_id}")
        if independent != primary:
            issues.append(f"continuant reference disagrees: {case_id}")

    maximum = next((case for case in cases if isinstance(case, dict)
                    and case.get("id") == "maximum-valid-frame-and-output"), None)
    if (maximum is None or maximum.get("input_length") != MAX_VALID_INPUT_LENGTH
            or maximum.get("expected_result") != MAX_OUTPUT_BYTES):
        issues.append("maximum valid frame/output fixture is missing")
    short = next((case for case in cases if isinstance(case, dict)
                  and case.get("id") == "maximum-output-one-byte-short"), None)
    if (short is None or short.get("output_capacity") != MAX_OUTPUT_BYTES - 1
            or short.get("expected_result") != -2):
        issues.append("one-byte-short maximum-output fixture is missing")
    singular = next((case for case in cases if isinstance(case, dict)
                     and case.get("id") == "zero-C-final-stage-before-capacity"), None)
    if (singular is None or singular.get("output_capacity") != 0
            or singular.get("expected_result") != -1):
        issues.append("strict final-C zero-divisor fixture is missing")
    parseable = next((case for case in cases if isinstance(case, dict)
                      and case.get("id") == "maximum-parseable-trailing-word"), None)
    if (parseable is None or parseable.get("input_length") != MAX_PARSEABLE_INPUT_LENGTH
            or parseable.get("expected_result") != -1):
        issues.append("maximum parseable malformed frame fixture is missing")
    return issues


def verify_workload() -> int:
    issues = workload_issues()
    if issues:
        raise ValueError("\n".join(issues))
    return len(json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))["cases"])


if __name__ == "__main__":
    print(verify_workload())
