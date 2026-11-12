"""Static package inventory checks; deliberately does not execute the ports."""

from __future__ import annotations

import json
from pathlib import Path

from common_interval_decomposition_tree_oracle import (
    MAX_OUTPUT_BYTES,
    expected_output,
    validate_output,
)

ROOT = Path(__file__).resolve().parents[1]
LANGUAGE_PATHS = {
    "c": ROOT / "c/c/common_interval_decomposition_tree.c",
    "c3": ROOT / "c3/c/common_interval_decomposition_tree.c3",
    "cpp": ROOT / "cpp/c/common_interval_decomposition_tree.cpp",
    "elisa": ROOT / "elisa/c/common_interval_decomposition_tree.elisa",
    "mojo": ROOT / "mojo/c/common_interval_decomposition_tree.mojo",
    "nim": ROOT / "nim/c/common_interval_decomposition_tree.nim",
    "odin": ROOT / "odin/c/common_interval_decomposition_tree.odin",
    "rust": ROOT / "rust/c/common_interval_decomposition_tree.rs",
    "v": ROOT / "v/c/common_interval_decomposition_tree.v",
    "zig": ROOT / "zig/c/common_interval_decomposition_tree.zig",
}


def static_issues() -> list[str]:
    package = ROOT / "benchmarks/c/common_interval_decomposition_tree"
    metadata = json.loads((package / "workload.json").read_text())
    issues = []
    if metadata.get("function_symbol") != "common_interval_decomposition_tree":
        issues.append("unexpected exported symbol")
    if metadata.get("abi") != "i64_array_bytes_output":
        issues.append("unexpected ABI")
    if metadata.get("input", {}).get("n_range") != [1, 48]:
        issues.append("workload bound mismatch")
    if metadata.get("output", {}).get("maximum_bytes") != 3048:
        issues.append("output capacity must match the 2n-1 tree bound")
    for case in metadata.get("cases", []):
        result, payload = expected_output(
            case.get("input_values", []),
            output_capacity=case.get("output_capacity"),
            output_is_null=case.get("output_is_null", False),
            input_is_null=case.get("input_is_null", False),
            input_length=case.get("input_length"),
        )
        if result != case.get("expected_result"):
            issues.append(f"oracle result mismatch for workload case {case.get('id')}")
        if ("expected_output_hex" in case
                and payload.hex() != case.get("expected_output_hex")):
            issues.append(f"oracle bytes mismatch for workload case {case.get('id')}")
        if result >= 0 and not validate_output(case.get("input_values", []), payload):
            issues.append(f"invalid oracle certificate for workload case {case.get('id')}")
    for profile in metadata.get("profile_inputs", []):
        values = profile.get("input_values", [])
        result, payload = expected_output(values, output_capacity=MAX_OUTPUT_BYTES)
        if result < 0 or not validate_output(values, payload):
            issues.append(f"invalid profile input or certificate: {profile.get('id')}")
    for language, path in LANGUAGE_PATHS.items():
        if not path.is_file():
            issues.append(f"missing {language} source: {path.relative_to(ROOT)}")
        elif "common_interval_decomposition_tree" not in path.read_text():
            issues.append(f"missing symbol text in {path.relative_to(ROOT)}")
    for filename in ("README.md", "RIGHTS.md"):
        if not (package / filename).is_file():
            issues.append(f"missing package document {filename}")
    if not (ROOT / "benchmarks/common_interval_decomposition_tree_oracle.py").is_file():
        issues.append("missing independent oracle")
    return issues
