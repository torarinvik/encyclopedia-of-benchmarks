"""Static inventory and provenance checks; never compiles or executes ports."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/i/influence_maximization_greedy_live_edge"
ALGORITHM = "influence_maximization_greedy_live_edge"
LANGUAGE_PATHS = {
    "c": "c/i/influence_maximization_greedy_live_edge.c",
    "c3": "c3/i/influence_maximization_greedy_live_edge.c3",
    "cpp": "cpp/i/influence_maximization_greedy_live_edge.cpp",
    "elisa": "elisa/i/influence_maximization_greedy_live_edge.elisa",
    "mojo": "mojo/i/influence_maximization_greedy_live_edge.mojo",
    "nim": "nim/i/influence_maximization_greedy_live_edge.nim",
    "odin": "odin/i/influence_maximization_greedy_live_edge.odin",
    "rust": "rust/i/influence_maximization_greedy_live_edge.rs",
    "v": "v/i/influence_maximization_greedy_live_edge.v",
    "zig": "zig/i/influence_maximization_greedy_live_edge.zig",
}
REQUIRED_CASES = {
    "single-vertex-zero-budget",
    "isolated-vertices-tie-by-id-over-two-worlds",
    "directed-chain-single-seed",
    "world-masks-select-largest-mean-reach",
    "disjoint-components-diminishing-gain-trace",
    "directed-cycle-second-seed-has-zero-gain",
    "maximum-frame-and-output",
    "reject-trailing-word",
    "reject-duplicate-directed-arc",
    "reject-self-loop",
    "reject-world-mask-out-of-range",
    "reject-endpoint-out-of-range",
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
        issues.append("inventory identity, ABI, or ten-port list does not match the contract")
    for name in inventory.get("metadata", []):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package metadata: {name}")
    for language, relative in LANGUAGE_PATHS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} source: {relative}")
        elif ALGORITHM not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol marker in {relative}")

    ids = [case.get("id") for case in workload.get("cases", [])]
    if len(ids) != len(set(ids)) or set(ids) != REQUIRED_CASES:
        issues.append("workload case IDs do not match the reviewed contract fixture set")
    max_case = next((case for case in workload.get("cases", [])
                     if case.get("id") == "maximum-frame-and-output"), {})
    if (workload.get("input", {}).get("maximum_valid_length") != 76
            or workload.get("input", {}).get("maximum_parseable_length") != 77
            or workload.get("output", {}).get("maximum_bytes") != 136
            or workload.get("workspace", {}).get("bytes") != 4096
            or len(max_case.get("input_values", [])) != 76
            or max_case.get("expected_result") != 136
            or len(bytes.fromhex(max_case.get("expected_output_hex", ""))) != 136):
        issues.append("bounds or maximum-frame fixture differ from the reviewed contract")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8") if (PACKAGE / "README.md").is_file() else ""
    for phrase in (
            "10.1007/978-1-4939-2864-4_624", "Algorithm 1",
            "Equal sums choose the smallest vertex ID", "independent reference",
            "probabilistic approximation guarantee",
            "rumor_blocking_greedy_live_edge"):
        if phrase not in readme:
            issues.append(f"README is missing required source or contract text: {phrase}")
    return issues
