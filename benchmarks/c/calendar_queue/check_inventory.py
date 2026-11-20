"""Static source and workload checks; this file never executes a port."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/c/calendar_queue"
ALGORITHM = "calendar_queue"
LANGUAGE_PATHS = {
    "c": "c/calendar_queue.c",
    "c3": "c3/c/calendar_queue.c3",
    "cpp": "cpp/c/calendar_queue.cpp",
    "elisa": "elisa/c/calendar_queue.elisa",
    "mojo": "mojo/c/calendar_queue.mojo",
    "nim": "nim/c/calendar_queue.nim",
    "odin": "odin/c/calendar_queue.odin",
    "rust": "rust/c/calendar_queue.rs",
    "v": "v/c/calendar_queue.v",
    "zig": "zig/c/calendar_queue.zig",
}
CASE_IDS = {
    "empty-operation-tape",
    "stable-priority-ties",
    "full-calendar-fallback-for-distant-event",
    "resize-grow-and-shrink-trace",
    "maximum-live-events-and-growth",
    "reject-dequeue-from-empty",
    "reject-priority-before-current-time",
    "reject-priority-above-bound",
    "reject-unknown-opcode",
    "reject-nonzero-dequeue-argument",
    "reject-operation-count-over-bound",
    "maximum-frame-and-one-byte-short-output",
    "reject-trailing-word",
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
            issues.append(f"symbol marker missing in {relative}")

    cases = workload.get("cases", [])
    ids = [case.get("id") for case in cases]
    if len(ids) != len(set(ids)) or set(ids) != CASE_IDS:
        issues.append("workload fixture IDs differ from the reviewed case set")
    for case in cases:
        values = case.get("input_values", [])
        if not case.get("input_is_null") and case.get("input_length") != len(values):
            issues.append(f"input length differs from values in {case.get('id')}")

    maximum = next((case for case in cases
                    if case.get("id") == "maximum-frame-and-one-byte-short-output"), {})
    maximum_live = next((case for case in cases
                         if case.get("id") == "maximum-live-events-and-growth"), {})
    live_values = maximum_live.get("input_values", [])
    live_operations = list(zip(live_values[1::2], live_values[2::2])) if live_values else []
    if (len(maximum.get("input_values", [])) != 257
            or maximum.get("input_length") != 257
            or maximum.get("output_capacity") != 1031
            or maximum.get("expected_result") != -2
            or workload.get("input", {}).get("maximum_valid_length") != 257
            or workload.get("input", {}).get("maximum_parseable_length") != 258
            or workload.get("output", {}).get("maximum_bytes") != 1032
            or workload.get("workspace", {}).get("bytes") != 8192
            or inventory.get("contract", {}).get("workspace_bytes") != 8192
            or len(live_values) != 131
            or maximum_live.get("input_length") != 131
            or live_values[0] != 65
            or live_operations[:64] != [(1, 0)] * 64
            or live_operations[64:] != [(2, 0)]
            or maximum_live.get("output_capacity") != 24
            or maximum_live.get("expected_result") != 24
            or maximum_live.get("expected_output_hex") != "010000000000000000000000000000000000000000000000"):
        issues.append("maximum frame, capacity, or workspace differs from the contract")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for phrase in (
            "10.1145/63039.63045", "bucket_count / 2 - 2",
            "exact rational widths", "full-calendar fallback", "8,192 bytes"):
        if phrase not in readme:
            issues.append(f"README is missing pinned profile text: {phrase}")
    return issues
