"""Static source/workload inventory review; this module never runs ports."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks" / "m" / "minimum_parenthesis_removal_bfs"
LANGUAGES = {
    "c": "c/m/minimum_parenthesis_removal_bfs.c",
    "c3": "c3/m/minimum_parenthesis_removal_bfs.c3",
    "cpp": "cpp/m/minimum_parenthesis_removal_bfs.cpp",
    "elisa": "elisa/m/minimum_parenthesis_removal_bfs.elisa",
    "mojo": "mojo/m/minimum_parenthesis_removal_bfs.mojo",
    "nim": "nim/m/minimum_parenthesis_removal_bfs.nim",
    "odin": "odin/m/minimum_parenthesis_removal_bfs.odin",
    "rust": "rust/m/minimum_parenthesis_removal_bfs.rs",
    "v": "v/m/minimum_parenthesis_removal_bfs.v",
    "zig": "zig/m/minimum_parenthesis_removal_bfs.zig",
}
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json", "workload.json",
    "check_inventory.py", "verify_workload.py",
)


def static_issues() -> list[str]:
    issues: list[str] = []
    for rel in LANGUAGES.values():
        if not (ROOT / rel).is_file():
            issues.append(f"missing language source: {rel}")
    for name in REQUIRED:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    for rel in ("benchmarks/minimum_parenthesis_removal_bfs_oracle.py",
                "benchmarks/minimum_parenthesis_removal_bfs_independent_oracle.py"):
        if not (ROOT / rel).is_file():
            issues.append(f"missing oracle: {rel}")
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [*issues, f"metadata cannot be read as JSON: {error}"]

    expected_sources = list(LANGUAGES.values())
    if inventory.get("algorithm") != "minimum_parenthesis_removal_bfs":
        issues.append("inventory algorithm name differs from package")
    if inventory.get("source_files") != expected_sources:
        issues.append("inventory source list differs from the ten-language contract")
    if inventory.get("bounds") != {
            "maximum_valid_input_values": 17,
            "maximum_parseable_input_values": 18,
            "maximum_output_bytes": 4354,
            "workspace_bytes": 8192}:
        issues.append("inventory bounds differ from the bounded profile")
    if workload.get("algorithm") != "minimum_parenthesis_removal_bfs":
        issues.append("workload algorithm name differs from package")
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (input_spec.get("maximum_valid_input_values") != 17
            or input_spec.get("maximum_parseable_input_values") != 18
            or input_spec.get("text_length_range") != [0, 16]):
        issues.append("workload input bounds differ from the bounded profile")
    if (output_spec.get("maximum_output_bytes") != 4354
            or workload.get("workspace", {}).get("bytes") != 8192):
        issues.append("workload output/workspace bounds differ from the bounded profile")
    cases = workload.get("cases", [])
    identifiers = [case.get("id") for case in cases if isinstance(case, dict)]
    if len(identifiers) != 13 or len(set(identifiers)) != len(identifiers):
        issues.append("workload case IDs are missing or duplicated")
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        values = case.get("input_values")
        input_length = case.get("input_length")
        if not isinstance(values, list) or type(input_length) is not int:
            issues.append(f"invalid fixture framing: {case.get('id')}")
            continue
        if case.get("input_is_null") is True:
            if values or input_length <= 0:
                issues.append(f"invalid null-input fixture: {case.get('id')}")
        elif input_length != len(values) or len(values) > 18:
            issues.append(f"input length mismatch: {case.get('id')}")
        expected_hex = case.get("expected_output_hex", "")
        try:
            output = bytes.fromhex(expected_hex)
        except (TypeError, ValueError):
            issues.append(f"invalid output hex: {case.get('id')}")
            continue
        expected_result = case.get("expected_result")
        if type(expected_result) is not int or (expected_result >= 0 and expected_result != len(output)):
            issues.append(f"fixture result does not match output length: {case.get('id')}")
        if expected_result in (-1, -2) and output:
            issues.append(f"error fixture contains output bytes: {case.get('id')}")
    return issues
