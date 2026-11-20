"""Static package metadata/source inventory review; never builds ports."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
ALGORITHM = "hypercube_edge_monotonicity_tester"
LANGUAGE_PATHS = [
    f"{language}/h/{ALGORITHM}.{extension}"
    for language, extension in (
        ("c", "c"), ("c3", "c3"), ("cpp", "cpp"), ("elisa", "elisa"),
        ("mojo", "mojo"), ("nim", "nim"), ("odin", "odin"),
        ("rust", "rs"), ("v", "v"), ("zig", "zig"),
    )
]
PACKAGE_FILES = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "inventory.json", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    "check_inventory.py",
)


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "inventory.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package metadata: {error}"]

    if (inventory.get("algorithm") != ALGORITHM
            or inventory.get("abi") != "i64_array_bytes_output"
            or inventory.get("ports") != LANGUAGE_PATHS):
        issues.append("inventory identity, ABI, or ten-port list differs from the package contract")
    for name in PACKAGE_FILES:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package metadata: {name}")
    for path in LANGUAGE_PATHS:
        source = ROOT / path
        if not source.is_file():
            issues.append(f"missing language source: {path}")
        elif ALGORITHM not in source.read_text(encoding="utf-8"):
            issues.append(f"export marker missing from {path}")

    if (workload.get("algorithm") != ALGORITHM
            or workload.get("function_symbol") != ALGORITHM
            or workload.get("abi") != inventory.get("abi")):
        issues.append("workload algorithm, symbol, or ABI differs from inventory")
    if (inventory.get("workspace_bytes") != 1024
            or workload.get("workspace", {}).get("bytes") != 1024
            or inventory.get("maximum_input_words") != 130
            or workload.get("input", {}).get("maximum_valid_length") != 130
            or workload.get("input", {}).get("maximum_parseable_length") != 131
            or inventory.get("maximum_output_bytes") != 24
            or workload.get("output", {}).get("maximum_bytes") != 24):
        issues.append("input, output, or workspace bounds differ from contract")
    for group in ("cases", "invalid_cases", "capacity_cases"):
        for case in workload.get(group, []):
            values = case.get("input_values", [])
            if case.get("input_length") is not None and not case.get("input_is_null"):
                if case["input_length"] != len(values):
                    issues.append(f"input length differs from values in {case.get('id')}")
            if case.get("expected_result", -1) >= 0:
                try:
                    payload = bytes.fromhex(case.get("expected_output_hex", ""))
                except (TypeError, ValueError):
                    issues.append(f"invalid expected-output hex in {case.get('id')}")
                    continue
                if len(payload) != case["expected_result"]:
                    issues.append(f"output length differs from result in {case.get('id')}")
    return issues
