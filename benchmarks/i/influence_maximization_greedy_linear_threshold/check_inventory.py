"""Static inventory checks only; this module never compiles or runs ports."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/i/influence_maximization_greedy_linear_threshold"
ALGORITHM = "influence_maximization_greedy_linear_threshold"
LANGUAGE_PATHS = {
    "c": "c/i/influence_maximization_greedy_linear_threshold.c",
    "c3": "c3/i/influence_maximization_greedy_linear_threshold.c3",
    "cpp": "cpp/i/influence_maximization_greedy_linear_threshold.cpp",
    "elisa": "elisa/i/influence_maximization_greedy_linear_threshold.elisa",
    "mojo": "mojo/i/influence_maximization_greedy_linear_threshold.mojo",
    "nim": "nim/i/influence_maximization_greedy_linear_threshold.nim",
    "odin": "odin/i/influence_maximization_greedy_linear_threshold.odin",
    "rust": "rust/i/influence_maximization_greedy_linear_threshold.rs",
    "v": "v/i/influence_maximization_greedy_linear_threshold.v",
    "zig": "zig/i/influence_maximization_greedy_linear_threshold.zig",
}
REQUIRED_CASES = {
    "single-vertex-zero-budget",
    "isolated-vertices-tie-by-id-over-two-worlds",
    "directed-chain-single-seed",
    "weighted-parent-intervals-and-low-id-tie",
    "diminishing-gain-on-two-trigger-components",
    "directed-parent-cycle-and-zero-second-gain",
    "leftover-range-selects-no-parent",
    "maximum-frame-and-output",
    "maximum-output-one-byte-short",
    "reject-trailing-word",
    "reject-duplicate-directed-edge",
    "reject-self-loop",
    "reject-edge-weight-out-of-range",
    "reject-incoming-weight-sum-over-scale",
    "reject-draw-out-of-range",
    "null-input",
    "null-output",
    "insufficient-output-capacity",
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
            or inventory.get("languages") != LANGUAGE_PATHS):
        issues.append("inventory identity, ABI, or language map differs from the contract")
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
    maximum = next((case for case in cases if case.get("id") == "maximum-frame-and-output"), {})
    try:
        max_output = bytes.fromhex(maximum.get("expected_output_hex", ""))
    except ValueError:
        max_output = b""
        issues.append("maximum output fixture contains invalid hexadecimal")
    if (workload.get("input", {}).get("maximum_valid_length") != 140
            or workload.get("input", {}).get("maximum_parseable_length") != 141
            or workload.get("output", {}).get("maximum_bytes") != 136
            or workload.get("workspace", {}).get("bytes") != 4096
            or len(maximum.get("input_values", [])) != 140
            or maximum.get("expected_result") != 136
            or len(max_output) != 136):
        issues.append("workload bounds or maximum-frame fixture differ from contract")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for phrase in (
            "10.1007/978-1-4939-2864-4_710", "10.4086/toc.2015.v011a004",
            "supplied finite-world profile", "does not sample mutually exclusive",
            "smallest vertex ID"):
        if phrase not in readme:
            issues.append(f"README is missing required source or profile text: {phrase}")
    return issues
