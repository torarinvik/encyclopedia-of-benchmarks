"""Static package inventory and fixture review for Myers O(ND) scripts."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .primary_oracle import (
        MAX_INPUT_LENGTH,
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_LENGTH,
        MAX_SEQUENCE_LENGTH,
        expected_output as primary_output,
    )
    from .independent_oracle import verify_output as independent_verify
except ImportError:  # Direct import from this package directory.
    from primary_oracle import (
        MAX_INPUT_LENGTH,
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_LENGTH,
        MAX_SEQUENCE_LENGTH,
        expected_output as primary_output,
    )
    from independent_oracle import verify_output as independent_verify

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": (ROOT / "c/m/myers_ond_shortest_edit_script.c", "c/m/myers_ond_shortest_edit_script.c"),
    "c3": (ROOT / "c3/m/myers_ond_shortest_edit_script.c3", "c3/m/myers_ond_shortest_edit_script.c3"),
    "cpp": (ROOT / "cpp/m/myers_ond_shortest_edit_script.cpp", "cpp/m/myers_ond_shortest_edit_script.cpp"),
    "elisa": (ROOT / "elisa/m/myers_ond_shortest_edit_script.elisa", "elisa/m/myers_ond_shortest_edit_script.elisa"),
    "mojo": (ROOT / "mojo/m/myers_ond_shortest_edit_script.mojo", "mojo/m/myers_ond_shortest_edit_script.mojo"),
    "nim": (ROOT / "nim/m/myers_ond_shortest_edit_script.nim", "nim/m/myers_ond_shortest_edit_script.nim"),
    "odin": (ROOT / "odin/m/myers_ond_shortest_edit_script.odin", "odin/m/myers_ond_shortest_edit_script.odin"),
    "rust": (ROOT / "rust/m/myers_ond_shortest_edit_script.rs", "rust/m/myers_ond_shortest_edit_script.rs"),
    "v": (ROOT / "v/m/myers_ond_shortest_edit_script.v", "v/m/myers_ond_shortest_edit_script.v"),
    "zig": (ROOT / "zig/m/myers_ond_shortest_edit_script.zig", "zig/m/myers_ond_shortest_edit_script.zig"),
}

REQUIRED_CASES = {
    "both_empty", "empty_first", "empty_second", "identical",
    "one_symbol_substitution_as_delete_insert", "ambiguous_lcs_pins_wavefront_tie",
    "interior_delete_insert", "two_end_insertions", "repeated_symbol_tie",
    "nul_and_high_byte_symbols", "maximum_identical_sequences", "maximum_disjoint_sequences",
    "invalid_symbol_above_byte", "invalid_negative_symbol", "negative_sequence_length",
    "oversized_sequence", "trailing_input_word", "short_capacity", "short_maximum_capacity",
    "null_output_for_empty_script", "invalid_input_precedes_null_output",
    "null_input_positive_length", "two_trailing_words_at_parseable_bound",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "myers_ond_shortest_edit_script"
            or workload.get("function_symbol") != "myers_ond_shortest_edit_script"
            or workload.get("abi") != "i64_array_bytes_output"):
        issues.append("workload identity or ABI mismatch")
    input_spec = workload.get("input", {})
    if (input_spec.get("sequence_length_range") != [0, MAX_SEQUENCE_LENGTH]
            or input_spec.get("maximum_valid_length") != MAX_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_LENGTH):
        issues.append("input bounds mismatch")
    output_spec = workload.get("output", {})
    if output_spec.get("maximum_output_bytes") != MAX_OUTPUT_BYTES:
        issues.append("output bound mismatch")
    if workload.get("workspace", {}).get("bytes") != MAX_OUTPUT_BYTES:
        issues.append("output workspace mismatch")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases must be a nonempty list"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid workload case")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture id: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        input_is_null = case.get("input_is_null", False)
        input_length = case.get("input_length")
        if (not isinstance(values, list) or type(input_is_null) is not bool
                or type(input_length) is not int
                or not input_is_null and input_length != len(values)
                or input_is_null and values):
            issues.append(f"input framing mismatch: {case_id}")
            continue
        args = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": input_is_null,
            "input_length": input_length,
        }
        try:
            expected = (case.get("expected_result"), bytes.fromhex(case.get("expected_output_hex", "")))
        except (TypeError, ValueError):
            issues.append(f"bad output hex: {case_id}")
            continue
        primary = primary_output(values, **args)
        if primary != expected:
            issues.append(f"primary fixture mismatch: {case_id}")
        if not independent_verify(values, *primary, **args):
            issues.append(f"independent replay/optimality check failed: {case_id}")
    if not REQUIRED_CASES <= seen:
        issues.append("missing fixtures: " + ", ".join(sorted(REQUIRED_CASES - seen)))

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for language, (path, relative) in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} source: {path.relative_to(ROOT)}")
            continue
        source = path.read_text(encoding="utf-8")
        if "myers_ond_shortest_edit_script" not in source:
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README source link mismatch for {language}")
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    return issues


def verify() -> None:
    """Raise if package files or fixture expectations are incomplete."""
    issues = static_issues()
    if issues:
        raise ValueError("\n".join(issues))
