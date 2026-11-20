"""Static fixture, source-link, and ten-language inventory checks."""

from __future__ import annotations

import json
import re
from pathlib import Path

from .independent_oracle import expected_result as independent
from .primary_oracle import (
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_RESULT,
    MAX_VALID_INPUT_LENGTH,
    expected_result as primary,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/o/order_maintenance"
SYMBOL = "order_maintenance"
SOURCE_URL = (
    "https://github.com/spaghetti-source/algorithm/blob/"
    "4fdac8202e26def25c1baf9127aaaed6a2c9f7c7/data_structure/order_maintenance.cc"
)
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "insert-after-and-order-query", "front-insertion-reverses-comparison",
    "self-order-is-false", "empty-trace", "relabel-after-narrow-gap",
    "wraparound-relabel-preserves-order",
    "maximum-insertions", "maximum-frame-and-checksum", "invalid-opcode",
    "insert-after-unknown-id", "nonsequential-new-id", "query-before-insert",
    "capacity-above-bound", "operation-count-above-bound", "trailing-word",
    "null-input", "null-at-parser-limit",
}


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")

    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "o" / f"{SYMBOL}.{extension}"
        if not path.is_file():
            issues.append(f"missing language port: {language}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {language}")

    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        for target in re.findall(r"\]\(([^)]+)\)", readme):
            if target.startswith(("https://", "http://", "#")):
                continue
            if not (PACKAGE / target).resolve().is_file():
                issues.append(f"unresolved README target: {target}")
        if SOURCE_URL not in readme or "deletion is excluded" not in readme:
            issues.append("README is missing the pinned source or scope limitation")
    except OSError as error:
        issues.append(f"cannot read README: {error}")

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
    if not all(isinstance(section, dict) for section in
               (input_spec, output_spec, profile, source)):
        return issues + ["workload metadata sections must be objects"]
    if (workload.get("id") != "dietz-sleator-order-maintenance-i64-array-scalar-v1"
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or source.get("url") != SOURCE_URL
            or input_spec.get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_input_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_spec.get("label_modulus") != 2_147_483_648
            or input_spec.get("label_ring") != 4_294_967_296
            or output_spec.get("valid_result_range") != [0, MAX_RESULT]
            or output_spec.get("invalid_input_result") != -1
            or profile.get("maximum_result_derivation") != (
                "A true query requires two earlier inserts, so at most query positions 3 through 128 contribute; their one-based sum is 8253.")):
        issues.append("workload identity, limits, label modulus, or output bounds differ")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing workload cases"]
    seen: set[str] = set()
    max_frame_seen = False
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
        expected = case.get("expected_result")
        input_is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int
                or type(expected) is not int or type(input_is_null) is not bool
                or (input_is_null and (values or not 0 <= length <= MAX_PARSEABLE_INPUT_LENGTH))
                or (not input_is_null and (length != len(values)
                                           or length > MAX_PARSEABLE_INPUT_LENGTH))):
            issues.append(f"invalid workload framing: {case_id}")
            continue
        if case_id == "maximum-frame-and-checksum":
            max_frame_seen = length == MAX_VALID_INPUT_LENGTH and expected == MAX_RESULT
        if primary(values, input_is_null, length) != expected:
            issues.append(f"primary-reference mismatch: {case_id}")
        if independent(values, input_is_null, length) != expected:
            issues.append(f"independent-reference mismatch: {case_id}")

    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))
    if not max_frame_seen:
        issues.append("maximum valid frame and checksum fixture is missing")
    return issues
