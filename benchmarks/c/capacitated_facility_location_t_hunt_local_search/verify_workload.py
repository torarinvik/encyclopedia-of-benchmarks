"""Static workload, contract, oracle, and ten-port inventory checks."""

from __future__ import annotations

import json
import re
from pathlib import Path

from .independent_oracle import expected_output as independent
from .primary_oracle import (
    MAX_CLIENTS,
    MAX_FACILITY_TYPES,
    MAX_INITIAL_COPIES,
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    expected_output as primary,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/c/capacitated_facility_location_t_hunt_local_search"
SYMBOL = "capacitated_facility_location_t_hunt_local_search"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "single-copy-add-improves",
    "t-hunt-drops-two-copies-adds-one",
    "maximum-valid-frame-no-improvement",
    "initial-capacity-insufficient",
    "maximum-valid-frame-plus-one-word",
    "short-output-capacity",
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
        path = ROOT / language / "c" / f"{SYMBOL}.{extension}"
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
    profile = workload.get("algorithm_profile", {})
    source = workload.get("source", {})
    measurement = workload.get("measurement", {})
    if (
        workload.get("id") != "encyclopedia-capacitated-facility-location-t-hunt-outer-loop-i64-array-bytes-output-v1"
        or workload.get("algorithm") != SYMBOL
        or workload.get("function_symbol") != SYMBOL
        or workload.get("abi") != "i64_array_bytes_output"
        or source.get("chapter_doi") != "10.1007/978-1-4939-2864-4_212"
        or source.get("paper_doi") != "10.1137/S0097539702416402"
        or measurement.get("comparison_model") != "i64_array_bytes_output_call"
        or input_spec.get("encoding") != "[n,F,Q,D[(n+F)^2 row-major],opening_fee[F],capacity[F],copy_type[Q]]"
        or input_spec.get("client_count_range") != [1, MAX_CLIENTS]
        or input_spec.get("facility_type_count_range") != [1, MAX_FACILITY_TYPES]
        or input_spec.get("initial_copy_count_range") != [1, MAX_INITIAL_COPIES]
        or input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
        or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
        or output_spec.get("maximum_bytes") != MAX_OUTPUT_BYTES
        or output_spec.get("maximum_accepted_steps") != 160
        or output_spec.get("maximum_final_copies") != 644
        or output_spec.get("invalid_input_result") != -1
        or output_spec.get("null_output_result") != -2
        or output_spec.get("insufficient_capacity_result") != -2
        or "recompute the minimum-cost assignment" not in profile.get("outer_loop", "")
        or "not a complete oracle" not in profile.get("termination_note", "")
    ):
        issues.append("workload identity, source, ABI, bounds, or profile differs")

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
        length = case.get("input_length")
        expected_result = case.get("expected_result")
        expected_hex = case.get("expected_output_hex")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        capacity = case.get("output_capacity")
        if (
            not isinstance(values, list)
            or type(length) is not int
            or type(expected_result) is not int
            or not isinstance(expected_hex, str)
            or type(input_is_null) is not bool
            or type(output_is_null) is not bool
            or type(capacity) is not int
            or (not input_is_null and length != len(values))
            or (input_is_null and values != [])
        ):
            issues.append(f"invalid workload fields: {case_id}")
            continue
        if case_id == "maximum-valid-frame-no-improvement" and (
                length != MAX_VALID_INPUT_LENGTH or expected_result != 88):
            issues.append("maximum valid frame differs from declared bound")
        if case_id == "maximum-valid-frame-plus-one-word" and (
                length != MAX_PARSEABLE_INPUT_LENGTH or expected_result != -1):
            issues.append("maximum parseable frame differs from declared bound")
        if case_id == "null-input-at-parser-limit" and (
                values != [] or length != MAX_PARSEABLE_INPUT_LENGTH or not input_is_null):
            issues.append("null-at-parser-limit representation differs")

        args = {
            "capacity": capacity,
            "input_length": length,
            "input_is_null": input_is_null,
            "output_is_null": output_is_null,
        }
        primary_result, primary_bytes = primary(values, **args)
        independent_result, independent_bytes = independent(values, **args)
        if primary_result != expected_result or independent_result != expected_result:
            issues.append(f"oracle result mismatch: {case_id}")
        if primary_bytes.hex() != expected_hex or independent_bytes.hex() != expected_hex:
            issues.append(f"oracle bytes mismatch: {case_id}")

    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))
    return issues


verify = verify_workload
static_issues = verify_workload
