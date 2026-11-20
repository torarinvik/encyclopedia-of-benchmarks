"""Static workload/reference consistency helper; intentionally not run."""

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
        WORKSPACE_BYTES,
        expected_output,
    )
except ImportError:  # direct package-local invocation
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
        WORKSPACE_BYTES,
        expected_output,
    )

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SOURCE_URL = "https://dlmf.nist.gov/3.9#E13"
PORTS = (
    "c/l/levin_partial_sum_transform.c",
    "c3/l/levin_partial_sum_transform.c3",
    "cpp/l/levin_partial_sum_transform.cpp",
    "elisa/l/levin_partial_sum_transform.elisa",
    "mojo/l/levin_partial_sum_transform.mojo",
    "nim/l/levin_partial_sum_transform.nim",
    "odin/l/levin_partial_sum_transform.odin",
    "rust/l/levin_partial_sum_transform.rs",
    "v/l/levin_partial_sum_transform.v",
    "zig/l/levin_partial_sum_transform.zig",
)


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if (workload.get("algorithm") != "levin_partial_sum_transform"
            or workload.get("function_symbol") != "levin_partial_sum_transform"
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("source", {}).get("url") != SOURCE_URL):
        issues.append("workload identity or DLMF source differs")
    if (workload.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
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
        if case.get("input_length") != len(values) and not case.get("input_is_null", False):
            issues.append(f"fixture input_length mismatch: {case_id}")
        kwargs = {
            "output_capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        try:
            primary = expected_output(values, **kwargs)
            independent = independent_output(values, **kwargs)
        except (ArithmeticError, OverflowError, TypeError, ValueError) as error:
            issues.append(f"oracle could not classify {case_id}: {error}")
            continue
        expected_hex = case.get("expected_output_hex")
        try:
            expected_bytes = bytes.fromhex(expected_hex)
        except (TypeError, ValueError):
            issues.append(f"fixture output is not valid hex: {case_id}")
            continue
        if (primary[0] != case.get("expected_result") or primary[1] != expected_bytes):
            issues.append(f"fixture differs from integer-cleared oracle: {case_id}")
        if independent != primary:
            issues.append(f"direct Fraction oracle disagrees: {case_id}")
    maximum = next((case for case in cases if isinstance(case, dict)
                    and case.get("id") == "maximum-valid-frame"), None)
    if (maximum is None or maximum.get("input_length") != MAX_VALID_INPUT_LENGTH
            or maximum.get("expected_result") != MAX_OUTPUT_BYTES):
        issues.append("maximum valid frame/output fixture is missing")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing language port: {relative}")
        elif "levin_partial_sum_transform" not in path.read_text(encoding="utf-8"):
            issues.append(f"entrypoint marker missing: {relative}")
    return issues


def verify_workload() -> int:
    issues = workload_issues()
    if issues:
        raise ValueError("\n".join(issues))
    return len(json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))["cases"])
