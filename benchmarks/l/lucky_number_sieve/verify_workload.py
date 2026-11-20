"""Static inventory and fixture review; never launches language ports."""
from __future__ import annotations

import json
from pathlib import Path

try:
    from .primary_oracle import expected_output
    from .independent_oracle import verify_result
except ImportError:
    from primary_oracle import expected_output
    from independent_oracle import verify_result

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "lucky_number_sieve"
LANGUAGE_PATHS = {
    "c": ROOT / "c/l/lucky_number_sieve.c",
    "c3": ROOT / "c3/l/lucky_number_sieve.c3",
    "cpp": ROOT / "cpp/l/lucky_number_sieve.cpp",
    "elisa": ROOT / "elisa/l/lucky_number_sieve.elisa",
    "mojo": ROOT / "mojo/l/lucky_number_sieve.mojo",
    "nim": ROOT / "nim/l/lucky_number_sieve.nim",
    "odin": ROOT / "odin/l/lucky_number_sieve.odin",
    "rust": ROOT / "rust/l/lucky_number_sieve.rs",
    "v": ROOT / "v/l/lucky_number_sieve.v",
    "zig": ROOT / "zig/l/lucky_number_sieve.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (workload.get("schema_version") != 1
            or workload.get("id") != "lucky-number-sieve-bounded-prefix-v1"
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"):
        issues.append("unexpected workload identity or ABI")
    if (input_spec.get("maximum_valid_length") != 2
            or input_spec.get("maximum_parseable_length") != 3
            or input_spec.get("kind") != "signed_64_bit_integer_array"
            or input_spec.get("encoding") != "[mode, inclusive_bound]"
            or input_spec.get("inclusive_bound_range") != [0, MAX_BOUND]
            or input_spec.get("invalid_input_result") != -1
            or input_spec.get("mode_values") != {
                "0": "positive odd candidates, standard lucky sequence",
                "1": "positive even candidates, even-lucky sequence",
            }):
        issues.append("unexpected valid-input or mode bounds")
    if (output_spec.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or output_spec.get("invalid_input_result") != -1
            or output_spec.get("null_output_result") != -2
            or output_spec.get("insufficient_output_capacity_result") != -2
            or output_spec.get("success_result") != "number of bytes written"
            or output_spec.get("kind") != "byte_array"
            or output_spec.get("output_untouched_on_error") is not True
            or output_spec.get("nonnull_output_required_for_empty_result") is not True
            or workload.get("workspace", {}).get("bytes") != MAX_OUTPUT_BYTES
            or workload.get("measurement", {}).get("comparison_model")
            != "i64_array_bytes_output_call"
            or workload.get("source", {}).get("url")
            != "https://rosettacode.org/wiki/Lucky_and_even_lucky_numbers"):
        issues.append("unexpected output, workspace, measurement, or source contract")
    cases = workload.get("cases", [])
    if not isinstance(cases, list) or not cases:
        return issues + ["missing workload cases"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid workload case record")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate workload case: {case_id}")
        seen.add(case_id)
        values = case.get("input_values", [])
        result, payload = expected_output(
            values, capacity=case.get("output_capacity"),
            output_is_null=case.get("output_is_null", False),
            input_is_null=case.get("input_is_null", False),
            input_length=case.get("input_length"),
        )
        case_id = case.get("id")
        if result != case.get("expected_result") or payload.hex() != case.get("expected_output_hex"):
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if not verify_result(
            values, result, payload, output_capacity=case.get("output_capacity"),
            output_is_null=case.get("output_is_null", False),
            input_is_null=case.get("input_is_null", False),
            input_length=case.get("input_length"),
        ):
            issues.append(f"independent verifier rejected fixture: {case_id}")
    for language, path in LANGUAGE_PATHS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                 "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file {name}")
    if not (ROOT / "benchmarks/verify_lucky_number_sieve.py").is_file():
        issues.append("missing dedicated suite verifier")
    return issues
