"""Static package inventory, ABI metadata, and oracle-fixture review."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import expected_output as direct_expected
    from .primary_oracle import (
        MAX_PARSEABLE_INPUT_VALUES,
        MAX_VALID_INPUT_VALUES,
        MAX_OUTPUT_BYTES,
        MAX_SCRATCH_BYTES,
        expected_output as pyramid_expected,
    )
except ImportError:
    from independent_oracle import expected_output as direct_expected
    from primary_oracle import (
        MAX_PARSEABLE_INPUT_VALUES,
        MAX_VALID_INPUT_VALUES,
        MAX_OUTPUT_BYTES,
        MAX_SCRATCH_BYTES,
        expected_output as pyramid_expected,
    )

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/s/splash2_volrend_raymarch"
SYMBOL = "splash2_volrend_raymarch"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "transparent-volume-one-sample",
    "opaque-front-sample-terminates-with-premultiplied-gray",
    "fractional-trilinear-one-eighth-corner-weight",
    "two-front-to-back-samples-in-same-cell",
    "zero-opacity-color-is-skipped-by-pyramid",
    "short-output-capacity", "null-output",
    "invalid-side-precedes-null-output", "sample-outside-volume",
    "zero-direction-with-multiple-samples", "invalid-voxel-byte",
    "trailing-input-word", "null-input",
}


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, extension in EXTENSIONS.items():
        relative = f"{language}/s/{SYMBOL}.{extension}"
        source = ROOT / relative
        if not source.is_file():
            issues.append(f"missing port: {relative}")
        elif SYMBOL not in source.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {relative}")

    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload must be an object"]
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"
            or input_spec.get("exact_valid_length") != "3 + 2*S^3 + 6*R"
            or input_spec.get("maximum_valid_input_values") != MAX_VALID_INPUT_VALUES
            or input_spec.get("maximum_parseable_input_values") != MAX_PARSEABLE_INPUT_VALUES
            or output_spec.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != MAX_OUTPUT_BYTES
            or workload.get("memory", {}).get("internal_scratch_bytes") != MAX_SCRATCH_BYTES
            or output_spec.get("null_output_result") != -2
            or output_spec.get("insufficient_capacity_result") != -3
            or output_spec.get("input_validation_precedes_output_errors") is not True
            or output_spec.get("exact_bytes") != "5*R"
            or workload.get("measurement", {}).get("comparison_model")
                != "i64_array_bytes_output_call"):
        issues.append("workload identity, bounds, output errors, or workspace differs")

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
        if not isinstance(values, list):
            issues.append(f"missing input array: {case_id}")
            continue
        length = case.get("input_length", len(values))
        capacity = case.get("output_capacity")
        output_is_null = case.get("output_is_null", False)
        input_is_null = case.get("input_is_null", False)
        expected = case.get("expected_result")
        expected_hex = case.get("expected_output_hex")
        if (type(length) is not int or type(capacity) is not int
                or type(output_is_null) is not bool or type(input_is_null) is not bool
                or type(expected) is not int or not isinstance(expected_hex, str)):
            issues.append(f"invalid fixture fields: {case_id}")
            continue
        primary = pyramid_expected(values, capacity, output_is_null,
                                   input_is_null, length)
        direct = direct_expected(values, capacity, output_is_null,
                                 input_is_null, length)
        if (primary != direct or primary[0] != expected
                or primary[1].hex() != expected_hex.replace(" ", "").lower()):
            issues.append(f"fixture disagrees with oracle oracles: {case_id}")

    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if ("not a reimplementation of the protected SPLASH-2 program" not in readme
            or workload.get("provenance", {}).get("source_url") not in rights
            or workload.get("provenance", {}).get("opacity_pyramid_source_url") not in rights
            or "forbid redistribution" not in rights):
        issues.append("README or RIGHTS omits clean-room scope, provenance, or license note")
    for language, extension in EXTENSIONS.items():
        relative = f"{language}/s/{SYMBOL}.{extension}"
        if f"](../../../{relative})" not in readme:
            issues.append(f"README port target is missing or malformed: {relative}")
    return issues


static_issues = verify_workload
