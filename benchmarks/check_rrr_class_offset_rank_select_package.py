"""Inventory and fixture checks for the class/offset bitvector draft."""

from pathlib import Path

from workload_json import load_workload
from r.rrr_class_offset_rank_select.primary_oracle import expected_output as primary
from r.rrr_class_offset_rank_select.independent_oracle import expected_output as independent

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/r/rrr_class_offset_rank_select"
NAME = "rrr_class_offset_rank_select"
EXTENSIONS = {"c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa", "mojo": "mojo",
              "nim": "nim", "odin": "odin", "rust": "rs", "v": "v", "zig": "zig"}


def static_issues(workload=None):
    if workload is None:
        try:
            workload = load_workload(PACKAGE / "workload.json")
        except (OSError, ValueError) as error:
            return [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    issues = []
    spec, output = workload.get("input"), workload.get("output")
    if (workload.get("algorithm") != NAME or workload.get("function_symbol") != NAME
            or workload.get("abi") != "i64_array_bytes_output" or not isinstance(spec, dict)
            or spec.get("maximum_valid_length") != 35 or spec.get("maximum_parseable_length") != 36
            or not isinstance(output, dict) or output.get("maximum_bytes") != 128
            or output.get("output_untouched_on_error") is not True
            or workload.get("workspace", {}).get("bytes") != 512):
        issues.append("identity or bounds mismatch")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "r" / f"{NAME}.{extension}"
        if not path.is_file() or NAME not in path.read_text(encoding="utf-8"):
            issues.append(f"missing port or symbol: {language}")
    for name in ("README.md", "RIGHTS.md", "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing cases"]
    seen = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid case")
            continue
        name = case["id"]
        if name in seen:
            issues.append(f"duplicate case: {name}")
        seen.add(name)
        values, length, capacity = case.get("input_values"), case.get("input_length"), case.get("output_capacity")
        null_in, null_out = case.get("input_is_null", False), case.get("output_is_null", False)
        if (not isinstance(values, list) or type(length) is not int or type(capacity) is not int
                or capacity < 0 or type(null_in) is not bool or type(null_out) is not bool
                or null_in and (values or not 0 <= length <= 36)
                or not null_in and (length != len(values) or length > 36)):
            issues.append(f"invalid framing: {name}")
            continue
        try:
            expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
        except (KeyError, TypeError, ValueError):
            issues.append(f"invalid output: {name}")
            continue
        if type(expected[0]) is not int or primary(values, capacity, null_out, null_in, length) != expected or independent(values, capacity, null_out, null_in, length) != expected:
            issues.append(f"reference disagreement: {name}")
    if not {"block_boundary", "full_byte", "maximum_length_ones", "mixed_class_offsets", "zero_bits", "zero_queries", "short_output", "null_output", "invalid_before_capacity", "bits_outside_length", "invalid_opcode", "select_over_limit", "null_input"} <= seen:
        issues.append("missing required cases")
    return issues
