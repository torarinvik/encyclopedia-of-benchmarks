"""Static file/metadata checker; intentionally not run during drafting."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/t/two_left_hashing_operation_trace"
ALGORITHM = "two_left_hashing_operation_trace"
LANGUAGE_PATHS = {
    "c": "c/t/two_left_hashing_operation_trace.c",
    "c3": "c3/t/two_left_hashing_operation_trace.c3",
    "cpp": "cpp/t/two_left_hashing_operation_trace.cpp",
    "elisa": "elisa/t/two_left_hashing_operation_trace.elisa",
    "mojo": "mojo/t/two_left_hashing_operation_trace.mojo",
    "nim": "nim/t/two_left_hashing_operation_trace.nim",
    "odin": "odin/t/two_left_hashing_operation_trace.odin",
    "rust": "rust/t/two_left_hashing_operation_trace.rs",
    "v": "v/t/two_left_hashing_operation_trace.v",
    "zig": "zig/t/two_left_hashing_operation_trace.zig",
}
ARTIFACTS = (
    "README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
    "independent_oracle.py", "verify_workload.py", "check_inventory.py",
    "INVENTORY.md", "INVENTORY.json",
)


def static_issues() -> list[str]:
    issues: list[str] = []
    for rel in LANGUAGE_PATHS.values():
        if not (ROOT / rel).is_file():
            issues.append(f"missing language port: {rel}")
    for rel in ARTIFACTS:
        if not (PACKAGE / rel).is_file():
            issues.append(f"missing package artifact: {rel}")
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text())
        workload = json.loads((PACKAGE / "workload.json").read_text())
    except (OSError, json.JSONDecodeError) as exc:
        return issues + [f"cannot read package metadata: {exc}"]
    if inventory.get("algorithm") != ALGORITHM:
        issues.append("inventory algorithm id mismatch")
    if set(inventory.get("sources", [])) != set(LANGUAGE_PATHS.values()):
        issues.append("inventory source list differs from ten-port map")
    if workload.get("algorithm") != ALGORITHM:
        issues.append("workload algorithm id mismatch")
    for case in workload.get("cases", []):
        values = case.get("input_values", [])
        if case.get("input_length") != len(values):
            issues.append(f"{case.get('id', '<unnamed>')}: framed length mismatch")
        if len(values) > 162:
            issues.append(f"{case.get('id', '<unnamed>')}: input exceeds parse bound")
        encoded = case.get("expected_output_hex", "")
        try:
            payload = bytes.fromhex(encoded)
        except (TypeError, ValueError):
            issues.append(f"{case.get('id', '<unnamed>')}: malformed output hex")
            continue
        if case.get("expected_result", -1) >= 0 and len(payload) != case.get("expected_result"):
            issues.append(f"{case.get('id', '<unnamed>')}: output byte count differs from result")
    if not any(c.get("id") == "maximum-output-capacity-boundary" and
               c.get("input_length") == 161 and c.get("output_capacity") == 640 and
               c.get("expected_result") == 640 for c in workload.get("cases", [])):
        issues.append("missing successful 40-operation maximum-output case")
    return issues
