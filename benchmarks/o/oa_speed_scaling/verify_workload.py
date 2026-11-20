"""Static workload and package-inventory checks for OA speed scaling."""

from __future__ import annotations

import json
import re
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
MAX_VALID_INPUT_LENGTH = 7
MAX_PARSEABLE_INPUT_LENGTH = 8
MAX_OUTPUT = 152
PORTS = (
    "c/o/oa_speed_scaling.c",
    "c3/o/oa_speed_scaling.c3",
    "cpp/o/oa_speed_scaling.cpp",
    "elisa/o/oa_speed_scaling.elisa",
    "mojo/o/oa_speed_scaling.mojo",
    "nim/o/oa_speed_scaling.nim",
    "odin/o/oa_speed_scaling.odin",
    "rust/o/oa_speed_scaling.rs",
    "v/o/oa_speed_scaling.v",
    "zig/o/oa_speed_scaling.zig",
)


def verify_workload(workload: dict | None = None) -> list[str]:
    errors: list[str] = []
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text())
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    if workload.get("algorithm") != "oa_speed_scaling":
        errors.append("algorithm id is not oa_speed_scaling")
    if workload.get("function_symbol") != "oa_speed_scaling":
        errors.append("function symbol is not oa_speed_scaling")
    if workload.get("abi") != "i64_array_bytes_output":
        errors.append("ABI is not i64_array_bytes_output")
    input_spec = workload.get("input", {})
    if input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH:
        errors.append("maximum valid input length is not 7")
    if input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH:
        errors.append("maximum parseable input length is not 8")
    output_spec = workload.get("output", {})
    if output_spec.get("maximum_values") != 19 or output_spec.get("maximum_bytes") != MAX_OUTPUT:
        errors.append("output bound is not 19 signed 64-bit values / 152 bytes")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        errors.append("workload cases are missing")
        cases = []
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict):
            errors.append("case is not an object")
            continue
        case_id = case.get("id")
        if not isinstance(case_id, str) or not case_id or case_id in seen:
            errors.append("case id is empty or duplicated")
        else:
            seen.add(case_id)
        values = case.get("input_values")
        declared_length = case.get("input_length")
        if not isinstance(values, list) or type(declared_length) is not int:
            errors.append(f"{case_id}: input_values/input_length is malformed")
            continue
        if len(values) != declared_length and not case.get("input_is_null", False):
            errors.append(f"{case_id}: declared input length differs from values")
        if not 0 <= declared_length <= MAX_PARSEABLE_INPUT_LENGTH:
            errors.append(f"{case_id}: input length is outside the parser bound")
        result = case.get("expected_result")
        payload_hex = case.get("expected_output_hex")
        if type(result) is not int or not isinstance(payload_hex, str):
            errors.append(f"{case_id}: expected result or payload is malformed")
            continue
        if len(payload_hex) % 2 or any(ch not in "0123456789abcdef" for ch in payload_hex):
            errors.append(f"{case_id}: output hex is not lowercase byte encoding")
        if result > 0 and (result > MAX_OUTPUT or len(payload_hex) != result * 2):
            errors.append(f"{case_id}: successful payload size disagrees with result/bound")
        if result <= 0 and payload_hex:
            errors.append(f"{case_id}: error case must have an empty output payload")
        capacity = case.get("output_capacity")
        if type(capacity) is not int or not 0 <= capacity <= MAX_OUTPUT:
            errors.append(f"{case_id}: output capacity is outside the ABI bound")

    if ("null-input" not in seen or "trailing-value-at-parse-limit" not in seen
            or "three-segment-maximum-output" not in seen):
        errors.append("null-input, parser-limit, and maximum-output fixtures are required")
    for port in PORTS:
        if not (PACKAGE.parents[2] / port).is_file():
            errors.append(f"missing language port {port}")
    for required in ("README.md", "RIGHTS.md", "primary_oracle.py",
                     "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / required).is_file():
            errors.append(f"missing package file {required}")
    readme = (PACKAGE / "README.md").read_text()
    for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", readme):
        if "://" in target or target.startswith("#"):
            continue
        local = target.split("#", 1)[0]
        if local and not (PACKAGE / local).resolve().exists():
            errors.append(f"README target does not exist: {target}")
    return errors
