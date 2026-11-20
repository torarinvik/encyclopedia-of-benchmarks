"""Static package inventory checks; this module never compiles or runs ports."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/a/all_distances_sketch_k_mins"
ALGORITHM = "all_distances_sketch_k_mins"
LANGUAGE_PATHS = {
    "c": "c/a/all_distances_sketch_k_mins.c",
    "c3": "c3/a/all_distances_sketch_k_mins.c3",
    "cpp": "cpp/a/all_distances_sketch_k_mins.cpp",
    "elisa": "elisa/a/all_distances_sketch_k_mins.elisa",
    "mojo": "mojo/a/all_distances_sketch_k_mins.mojo",
    "nim": "nim/a/all_distances_sketch_k_mins.nim",
    "odin": "odin/a/all_distances_sketch_k_mins.odin",
    "rust": "rust/a/all_distances_sketch_k_mins.rs",
    "v": "v/a/all_distances_sketch_k_mins.v",
    "zig": "zig/a/all_distances_sketch_k_mins.zig",
}
REQUIRED_CASES = {
    "two-rank-rows-with-interleaved-records",
    "maximum-valid-frame-with-minimal-output",
    "single-item-nonzero-distance",
    "duplicate-rank-in-row",
    "distances-not-strictly-increasing",
    "assignment-count-above-bound",
    "trailing-word-after-maximum-frame",
    "invalid-rank-precedes-short-output",
    "short-output-capacity",
    "null-output",
    "null-input",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package metadata: {error}"]

    if (inventory.get("algorithm") != ALGORITHM
            or inventory.get("function_symbol") != ALGORITHM
            or inventory.get("abi") != "i64_array_bytes_output"
            or inventory.get("suite_integration")
                != "i64_array_bytes_output runner and verifier"
            or inventory.get("languages") != LANGUAGE_PATHS
            or workload.get("algorithm") != ALGORITHM
            or workload.get("function_symbol") != ALGORITHM
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("measurement", {}).get("comparison_model")
                != "i64_array_bytes_output_call"):
        issues.append("inventory identity, ABI, or ten-language map differs from the contract")
    for name in inventory.get("metadata", []):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package metadata: {name}")
    for language, relative in LANGUAGE_PATHS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} source: {relative}")
        elif ALGORITHM not in path.read_text(encoding="utf-8"):
            issues.append(f"exported symbol marker missing in {relative}")

    cases = workload.get("cases", [])
    case_ids = [case.get("id") for case in cases]
    if len(case_ids) != len(set(case_ids)) or set(case_ids) != REQUIRED_CASES:
        issues.append("workload fixture IDs differ from the reviewed case set")
    for case in cases:
        if not case.get("input_is_null") and case.get("input_length") != len(case.get("input_values", [])):
            issues.append(f"input length does not match values for {case.get('id')}")
        try:
            raw = bytes.fromhex(case.get("expected_output_hex", ""))
        except ValueError:
            raw = b""
            issues.append(f"invalid output hex for {case.get('id')}")
        if case.get("expected_result", -1) >= 0 and len(raw) != case["expected_result"]:
            issues.append(f"output byte count differs from result for {case.get('id')}")
        if case.get("expected_result", -1) < 0 and raw:
            issues.append(f"error fixture has output bytes for {case.get('id')}")

    maximum_frame = next((case for case in cases
                          if case.get("id") == "maximum-valid-frame-with-minimal-output"), {})
    if (workload.get("input", {}).get("maximum_valid_input_values") != 26
            or workload.get("input", {}).get("maximum_parseable_input_values") != 27
            or workload.get("output", {}).get("maximum_words") != 73
            or workload.get("output", {}).get("maximum_bytes") != 584
            or workload.get("workspace", {}).get("bytes") != 1024
            or len(maximum_frame.get("input_values", [])) != 26):
        issues.append("workload bounds do not match the documented n=6, assignment_count=3 profile")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for phrase in ("10.1145/1281100.1281133", "10.1007/978-1-4939-2864-4_574",
                   "MV/D list", "all-distances k-mins", "min_hash_k_mins"):
        if phrase not in readme:
            issues.append(f"README is missing required source or duplicate rationale: {phrase}")
    return issues
