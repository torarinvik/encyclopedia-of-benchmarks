"""Static package, source, and fixture inventory for the base-three variant."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_output as independent
from .primary_oracle import (
    DRAW_SPACE,
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_UPDATES,
    MAX_VALID_INPUT_LENGTH,
    WORKSPACE_BYTES,
    expected_output as primary,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/m/morris_approximate_counter_base_three"
SYMBOL = "morris_approximate_counter_base_three"
SOURCE_URL = "https://www.algorithm-archive.org/contents/approximate_counting/approximate_counting.html"
SOURCE_PATHS = {
    "c": ROOT / "c/m/morris_approximate_counter_base_three.c",
    "c3": ROOT / "c3/m/morris_approximate_counter_base_three.c3",
    "cpp": ROOT / "cpp/m/morris_approximate_counter_base_three.cpp",
    "elisa": ROOT / "elisa/m/morris_approximate_counter_base_three.elisa",
    "mojo": ROOT / "mojo/m/morris_approximate_counter_base_three.mojo",
    "nim": ROOT / "nim/m/morris_approximate_counter_base_three.nim",
    "odin": ROOT / "odin/m/morris_approximate_counter_base_three.odin",
    "rust": ROOT / "rust/m/morris_approximate_counter_base_three.rs",
    "v": ROOT / "v/morris_approximate_counter_base_three.v",
    "zig": ROOT / "zig/m/morris_approximate_counter_base_three.zig",
}
REQUIRED_CASES = {
    "empty-tape",
    "first-event-at-largest-draw",
    "second-event-just-below-threshold",
    "second-event-at-strict-threshold",
    "third-event-just-below-threshold",
    "third-event-at-strict-threshold",
    "maximum-tape-all-increments",
    "maximum-draws-after-first-event",
    "negative-update-count",
    "update-count-above-bound",
    "missing-draw",
    "negative-draw",
    "draw-at-exclusive-upper-bound",
    "extra-word-after-valid-frame",
    "maximum-parseable-length-extra-word",
    "invalid-input-precedes-capacity",
    "short-output-capacity-on-empty-tape",
    "null-output-on-empty-tape",
    "null-input",
}


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in (
        "README.md",
        "RIGHTS.md",
        "INVENTORY.md",
        "RESERVATION.md",
        "workload.json",
        "primary_oracle.py",
        "independent_oracle.py",
    ):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")

    for language, source in SOURCE_PATHS.items():
        if not source.is_file():
            issues.append(f"missing language source: {language}")
        elif SYMBOL not in source.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {language}")

    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload must be an object"]

    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (
        workload.get("algorithm") != SYMBOL
        or workload.get("function_symbol") != SYMBOL
        or workload.get("abi") != "i64_array_bytes_output"
        or workload.get("source", {}).get("url") != SOURCE_URL
        or input_spec.get("updates_range") != [0, MAX_UPDATES]
        or input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
        or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
        or input_spec.get("invalid_result") != -1
        or input_spec.get("null_input_result") != -1
        or output_spec.get("maximum_bytes") != MAX_OUTPUT_BYTES
        or output_spec.get("invalid_input_result") != -1
        or output_spec.get("null_output_result") != -2
        or output_spec.get("insufficient_output_capacity_result") != -2
        or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES
        or workload.get("measurement", {}).get("comparison_model")
        != "i64_array_bytes_output_call"
    ):
        issues.append("workload identity, bounds, output, or workspace differs")
    if input_spec.get("draw_range") != f"0..{DRAW_SPACE - 1}":
        issues.append("workload draw domain differs")

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
        is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        input_length = case.get(
            "input_length", len(values) if isinstance(values, list) else None
        )
        capacity = case.get("output_capacity")
        expected_result = case.get("expected_result")
        expected_hex = case.get("expected_output_hex")
        if (
            not isinstance(values, list)
            or type(is_null) is not bool
            or type(output_is_null) is not bool
            or type(input_length) is not int
            or type(capacity) is not int
            or type(expected_result) is not int
            or not isinstance(expected_hex, str)
            or (is_null and (values or input_length != 0))
            or (not is_null and input_length != len(values))
        ):
            issues.append(f"invalid workload case fields: {case_id}")
            continue
        try:
            expected_bytes = bytes.fromhex(expected_hex)
        except ValueError:
            issues.append(f"invalid expected output hex: {case_id}")
            continue
        options = {
            "capacity": capacity,
            "output_is_null": output_is_null,
            "input_is_null": is_null,
            "input_length": input_length,
        }
        expected = (expected_result, expected_bytes)
        if primary(values, **options) != expected or independent(values, **options) != expected:
            issues.append(f"fixture/reference mismatch: {case_id}")

    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))
    return issues
