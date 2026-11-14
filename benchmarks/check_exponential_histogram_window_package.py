"""Inventory and fixture checks for bounded exponential histograms."""

from pathlib import Path

from workload_json import load_workload
from e.exponential_histogram_window.primary_oracle import expected_output as primary
from e.exponential_histogram_window.independent_oracle import expected_output as independent

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/e/exponential_histogram_window"
NAME = "exponential_histogram_window"
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
    spec, output, workspace = workload.get("input"), workload.get("output"), workload.get("workspace")
    if (workload.get("schema_version") != 1
            or workload.get("id") != "exponential-histogram-window-i64-array-bytes-output-v1"
            or workload.get("algorithm") != NAME or workload.get("function_symbol") != NAME
            or workload.get("abi") != "i64_array_bytes_output" or not isinstance(spec, dict)
            or spec.get("kind") != "signed_64_bit_integer_array" or spec.get("encoding") != "[window,n,bits[n]]"
            or spec.get("maximum_valid_length") != 130 or spec.get("maximum_parseable_length") != 131
            or spec.get("invalid_input_result") != -1 or not isinstance(output, dict)
            or output.get("encoding") != "little-endian i64 twice-estimates for each stream prefix"
            or output.get("maximum_bytes") != 1024 or output.get("invalid_input_result") != -1
            or output.get("output_error_result") != -2 or output.get("output_untouched_on_error") is not True
            or not isinstance(workspace, dict) or workspace.get("bytes") != 1024):
        issues.append("identity or bounds mismatch")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "e" / f"{NAME}.{extension}"
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
        if (not isinstance(values, list)
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
                or type(length) is not int or type(capacity) is not int or capacity < 0
                or type(null_in) is not bool or type(null_out) is not bool
                or null_in and (values or not 0 <= length <= 131)
                or not null_in and (length != len(values) or length > 131)):
            issues.append(f"invalid framing: {name}")
            continue
        try:
            expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
        except (KeyError, TypeError, ValueError):
            issues.append(f"invalid output: {name}")
            continue
        args = (values, capacity, null_out, null_in, length)
        if type(expected[0]) is not int or primary(*args) != expected or independent(*args) != expected:
            issues.append(f"reference disagreement: {name}")
    if not {"empty", "zeros", "merge_and_expire", "single_bit_window", "invalid_window",
            "invalid_bit_before_output", "short_output", "null_output_empty", "null_input"} <= seen:
        issues.append("missing required cases")
    return issues
