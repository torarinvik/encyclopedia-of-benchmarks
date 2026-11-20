"""Static metadata/source review; this checker is intentionally not run here."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/i/interval_heap_double_ended"
ALGORITHM = "interval_heap_double_ended"
LANGUAGE_PATHS = {
    "c": "c/i/interval_heap_double_ended.c",
    "c3": "c3/i/interval_heap_double_ended.c3",
    "cpp": "cpp/i/interval_heap_double_ended.cpp",
    "elisa": "elisa/i/interval_heap_double_ended.elisa",
    "mojo": "mojo/i/interval_heap_double_ended.mojo",
    "nim": "nim/i/interval_heap_double_ended.nim",
    "odin": "odin/i/interval_heap_double_ended.odin",
    "rust": "rust/i/interval_heap_double_ended.rs",
    "v": "v/i/interval_heap_double_ended.v",
    "zig": "zig/i/interval_heap_double_ended.zig",
}
CASE_IDS = {
    "empty-heap-empty-trace",
    "insert-duplicate-keys-and-query-both-ends",
    "mixed-endpoint-extractions-and-reuse",
    "singleton-pairing-and-drain",
    "signed-i32-boundaries-at-both-ends",
    "maximum-valid-frame-one-byte-short-output",
    "count-on-empty",
    "reject-empty-find-min",
    "reject-empty-extract-max",
    "reject-unknown-opcode",
    "reject-nonzero-query-argument",
    "reject-insert-above-i32",
    "reject-trailing-word",
    "reject-one-byte-short-output",
    "reject-null-input",
    "reject-null-output",
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
        issues.append("inventory identity, ABI, or language map differs from the package contract")
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
    ids = [case.get("id") for case in cases]
    if len(ids) != len(set(ids)) or set(ids) != CASE_IDS:
        issues.append("workload fixture IDs differ from the reviewed case set")
    for case in cases:
        values = case.get("input_values", [])
        if not case.get("input_is_null") and case.get("input_length") != len(values):
            issues.append(f"input length differs from values in {case.get('id')}")

    short = next((case for case in cases if case.get("id") == "reject-one-byte-short-output"), {})
    maximum = next((case for case in cases if case.get("id") == "maximum-valid-frame-one-byte-short-output"), {})
    if (workload.get("input", {}).get("maximum_valid_length") != 322
            or workload.get("input", {}).get("maximum_live_values") != 192
            or workload.get("output", {}).get("maximum_bytes") != 1552
            or workload.get("workspace", {}).get("bytes") != 8192
            or inventory.get("contract", {}).get("maximum_output_bytes") != 1552
            or inventory.get("contract", {}).get("workspace_bytes") != 8192
            or short.get("output_capacity") != 23
            or short.get("expected_result") != -2
            or len(maximum.get("input_values", [])) != 322
            or maximum.get("input_length") != 322
            or maximum.get("output_capacity") != 1551
            or maximum.get("expected_result") != -2):
        issues.append("bounded input/output/workspace or capacity fixture differs from the package contract")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for phrase in ("10.1093/comjnl/36.3.209", "alternating min and max levels",
                   "1,552 bytes", "8,192 bytes", "Equal keys remain separate"):
        if phrase not in readme:
            issues.append(f"README is missing pinned profile text: {phrase}")
    return issues
