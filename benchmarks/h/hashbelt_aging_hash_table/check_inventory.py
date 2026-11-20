"""Static package inventory checker; do not execute during quiet-mode work."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/h/hashbelt_aging_hash_table"
ALGORITHM = "hashbelt_aging_hash_table"
LANGUAGE_PATHS = {
    "c": "c/h/hashbelt_aging_hash_table.c",
    "c3": "c3/h/hashbelt_aging_hash_table.c3",
    "cpp": "cpp/h/hashbelt_aging_hash_table.cpp",
    "elisa": "elisa/h/hashbelt_aging_hash_table.elisa",
    "mojo": "mojo/h/hashbelt_aging_hash_table.mojo",
    "nim": "nim/h/hashbelt_aging_hash_table.nim",
    "odin": "odin/h/hashbelt_aging_hash_table.odin",
    "rust": "rust/h/hashbelt_aging_hash_table.rs",
    "v": "v/h/hashbelt_aging_hash_table.v",
    "zig": "zig/h/hashbelt_aging_hash_table.zig",
}
CASE_IDS = {
    "empty-trace",
    "put-update-get-and-miss",
    "four-generation-expiry",
    "promoted-hit-refreshes-expiration",
    "put-moves-existing-key",
    "separate-chain-collision",
    "max-output-success",
    "max-output-one-byte-short",
    "invalid-frame-precedes-capacity",
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
            or inventory.get("languages") != LANGUAGE_PATHS):
        issues.append("inventory identity, ABI, or language paths differ from the reviewed contract")
    for name in inventory.get("metadata", []):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package metadata: {name}")
    for language, relative in LANGUAGE_PATHS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} source: {relative}")
        elif ALGORITHM not in path.read_text(encoding="utf-8"):
            issues.append(f"symbol marker missing in {relative}")

    cases = workload.get("cases", [])
    identifiers = [case.get("id") for case in cases]
    if len(identifiers) != len(set(identifiers)) or set(identifiers) != CASE_IDS:
        issues.append("workload fixture IDs differ from the reviewed case set")
    for case in cases:
        values = case.get("input_values", [])
        if not case.get("input_is_null") and case.get("input_length") != len(values):
            issues.append(f"input length differs from values in {case.get('id')}")
        if case.get("expected_result", 0) >= 0:
            try:
                decoded = bytes.fromhex(case.get("expected_output_hex", ""))
            except ValueError:
                issues.append(f"invalid expected-output hex in {case.get('id')}")
                continue
            if len(decoded) != case["expected_result"]:
                issues.append(f"output length differs from result in {case.get('id')}")
    contract = inventory.get("contract", {})
    if (workload.get("input", {}).get("maximum_valid_length") != 193
            or workload.get("input", {}).get("maximum_parseable_length") != 194
            or workload.get("output", {}).get("maximum_bytes") != 512
            or workload.get("workspace", {}).get("bytes") != 4096
            or contract.get("maximum_valid_input_words") != 193
            or contract.get("maximum_parseable_input_words") != 194
            or contract.get("maximum_output_bytes") != 512
            or contract.get("workspace_bytes") != 4096):
        issues.append("input/output/workspace bounds differ from the package contract")
    return issues
