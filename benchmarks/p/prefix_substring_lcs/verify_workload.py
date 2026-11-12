"""Static package inventory and oracle-fixture checks; launches no port."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import expected_output as independent_output
    from .primary_oracle import MAX_INPUT_LENGTH, MAX_OUTPUT_BYTES, expected_output as primary_output
except ImportError:  # Direct invocation from this package directory.
try:
    from .independent_oracle import expected_output as independent_output
    from .primary_oracle import MAX_INPUT_LENGTH, MAX_OUTPUT_BYTES, expected_output as primary_output
except ImportError:  # Direct invocation from this package directory.
    from independent_oracle import expected_output as independent_output
    from primary_oracle import MAX_INPUT_LENGTH, MAX_OUTPUT_BYTES, expected_output as primary_output

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": ROOT / "c/p/prefix_substring_lcs.c",
    "c3": ROOT / "c3/p/prefix_substring_lcs.c3",
    "cpp": ROOT / "cpp/p/prefix_substring_lcs.cpp",
    "elisa": ROOT / "elisa/p/prefix_substring_lcs.elisa",
    "mojo": ROOT / "mojo/p/prefix_substring_lcs.mojo",
    "nim": ROOT / "nim/p/prefix_substring_lcs.nim",
    "odin": ROOT / "odin/p/prefix_substring_lcs.odin",
    "rust": ROOT / "rust/p/prefix_substring_lcs.rs",
    "v": ROOT / "v/p/prefix_substring_lcs.v",
    "zig": ROOT / "zig/p/prefix_substring_lcs.zig",
}
REQUIRED_CASES = {
    "single-match-and-empty-ranges",
    "repeated-symbol-substrings",
    "mixed-prefix-substring-queries",
    "short-output-capacity",
    "null-output",
    "invalid-uppercase-character",
    "query-out-of-range",
    "malformed-packed-length",
    "empty-input",
    "null-input",
}


def verify() -> list[str]:
    errors: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"workload cannot be read: {error}"]
    if workload.get("algorithm") != "prefix_substring_lcs" or workload.get("abi") != "i64_array_bytes_output":
        errors.append("algorithm or ABI metadata mismatch")
    if workload.get("input", {}).get("maximum_valid_length") != MAX_INPUT_LENGTH:
        errors.append("packed input bound mismatch")
    if workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES:
        errors.append("output bound mismatch")
    if workload.get("oracle") != "benchmarks/p/prefix_substring_lcs/primary_oracle.py":
        errors.append("primary oracle path mismatch")
    if workload.get("independent_oracle") != "benchmarks/p/prefix_substring_lcs/independent_oracle.py":
        errors.append("independent oracle path mismatch")

    cases = workload.get("cases", [])
    case_ids = {case.get("id") for case in cases}
    if not REQUIRED_CASES <= case_ids:
        errors.append(f"missing workload fixtures: {sorted(REQUIRED_CASES - case_ids)}")
    for case in cases:
        case_id = case.get("id", "<unknown>")
        values = case.get("input_values", [])
        kwargs = {
            "capacity": case.get("output_capacity", MAX_OUTPUT_BYTES),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length", len(values)),
        }
        first = primary_output(values, **kwargs)
        second = independent_output(values, **kwargs)
        if first != second:
            errors.append(f"primary and independent oracles disagree: {case_id}")
        expected_hex = case.get("expected_output_hex", "")
        if first[0] != case.get("expected_result") or first[1].hex() != expected_hex:
            errors.append(f"fixture result mismatch: {case_id}")
        if len(values) > MAX_INPUT_LENGTH + 1:
            errors.append(f"fixture exceeds parseable input bound: {case_id}")

    for language, path in PORTS.items():
        if not path.is_file():
            errors.append(f"missing {language} source: {path.relative_to(ROOT)}")
        elif "prefix_substring_lcs" not in path.read_text(encoding="utf-8"):
            errors.append(f"symbol not found in {language} source")
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py", "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            errors.append(f"missing package file: {name}")
    return errors


if __name__ == "__main__":
    for error in verify():
        print(error)
