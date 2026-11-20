"""Static workload, contract, oracle, and source-inventory review."""

from __future__ import annotations

import json
import re
from pathlib import Path

from .independent_oracle import expected_output as independent
from .primary_oracle import (
    MAX_CLIENTS,
    MAX_DRAWS,
    MAX_FACILITIES,
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    expected_output as primary,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/f/facility_location_randomized_add_delete_many"
SYMBOL = "facility_location_randomized_add_delete_many"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "one-add-then-already-open-draw",
    "one-add-deletes-two-centers",
    "strict-zero-saving-center-is-kept",
    "opening-cost-blocks-move",
    "already-open-choice-is-noop",
    "maximum-valid-frame",
    "maximum-valid-frame-plus-one-word",
    "assignment-to-closed-facility",
    "draw-out-of-range",
    "short-output-capacity-at-maximum",
    "null-output",
    "null-input-empty",
    "null-input-at-parser-limit",
}


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "f" / f"{SYMBOL}.{extension}"
        if not path.is_file():
            issues.append(f"missing language source: {language}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {language}")

    readme = PACKAGE / "README.md"
    if readme.is_file():
        for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", readme.read_text(encoding="utf-8")):
            if "://" in target or target.startswith("#"):
                continue
            local = target.split("#", 1)[0]
            if local and not (PACKAGE / local).resolve().is_file():
                issues.append(f"README link target is missing: {target}")

    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload must be an object"]

    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    measurement = workload.get("measurement", {})
    source = workload.get("source", {})
    expected_input = (
        "[n,F,Q,initial_mask,assignment[n],demand[n],D[(n+F)^2 row-major],fee[F],draw[Q]]"
    )
    if (
        workload.get("algorithm") != SYMBOL
        or workload.get("function_symbol") != SYMBOL
        or workload.get("abi") != "i64_array_bytes_output"
        or workload.get("id") != "encyclopedia-facility-location-randomized-add-delete-many-i64-array-bytes-output-v1"
        or input_spec.get("kind") != "signed_64_bit_integer_array"
        or input_spec.get("encoding") != expected_input
        or input_spec.get("client_count_range") != [1, MAX_CLIENTS]
        or input_spec.get("facility_count_range") != [1, MAX_FACILITIES]
        or input_spec.get("draw_count_range") != [1, MAX_DRAWS]
        or input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
        or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
        or input_spec.get("invalid_input_result") != -1
        or output_spec.get("kind") != "little_endian_signed_64_bit_array"
        or output_spec.get("maximum_bytes") != MAX_OUTPUT_BYTES
        or output_spec.get("invalid_input_result") != -1
        or output_spec.get("null_output_result") != -2
        or output_spec.get("insufficient_capacity_result") != -2
        or measurement.get("comparison_model") != "i64_array_bytes_output_call"
        or source.get("paper_doi") != "10.1137/S0097539701398594"
    ):
        issues.append("workload identity, source, ABI, or declared bounds differ")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing workload cases"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid workload case")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate workload case: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        declared_length = case.get("input_length")
        expected_result = case.get("expected_result")
        expected_hex = case.get("expected_output_hex")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        capacity = case.get("output_capacity")
        if (
            not isinstance(values, list)
            or type(declared_length) is not int
            or type(expected_result) is not int
            or not isinstance(expected_hex, str)
            or type(input_is_null) is not bool
            or type(output_is_null) is not bool
            or (not input_is_null and declared_length != len(values))
            or (input_is_null and values != [])
            or type(capacity) is not int
        ):
            issues.append(f"invalid workload case fields: {case_id}")
            continue
        if case_id == "maximum-valid-frame" and (
            len(values) != MAX_VALID_INPUT_LENGTH
            or declared_length != MAX_VALID_INPUT_LENGTH
            or expected_result != MAX_OUTPUT_BYTES
        ):
            issues.append("maximum-valid-frame does not match declared bounds")
        if case_id == "maximum-valid-frame-plus-one-word" and (
            len(values) != MAX_PARSEABLE_INPUT_LENGTH
            or declared_length != MAX_PARSEABLE_INPUT_LENGTH
            or expected_result != -1
        ):
            issues.append("maximum-parseable fixture does not match declared bounds")
        if case_id == "null-input-at-parser-limit" and (
            values != [] or declared_length != MAX_PARSEABLE_INPUT_LENGTH or not input_is_null
        ):
            issues.append("null-at-parser-limit fixture does not use the null ABI representation")

        common = {
            "capacity": capacity,
            "input_length": declared_length,
            "input_is_null": input_is_null,
            "output_is_null": output_is_null,
        }
        primary_result, primary_bytes = primary(values, **common)
        independent_result, independent_bytes = independent(values, **common)
        if primary_result != expected_result or independent_result != expected_result:
            issues.append(f"reference result mismatch: {case_id}")
        if primary_bytes.hex() != expected_hex or independent_bytes.hex() != expected_hex:
            issues.append(f"reference output bytes mismatch: {case_id}")

    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))
    return issues


verify = verify_workload
static_issues = verify_workload
