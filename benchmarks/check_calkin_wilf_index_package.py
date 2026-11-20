"""Unexecuted inventory and fixture checks for Calkin–Wilf indexing."""
from pathlib import Path

from c.calkin_wilf_index.reference import expected_output, independent_output

ROOT = Path(__file__).resolve().parents[1]
EXTENSIONS = {"c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa", "mojo": "mojo",
              "nim": "nim", "odin": "odin", "rust": "rs", "v": "v", "zig": "zig"}


def static_issues(workload):
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    issues = []
    spec, output, workspace = workload.get("input"), workload.get("output"), workload.get("workspace")
    if (workload.get("schema_version") != 1 or workload.get("algorithm") != "calkin_wilf_index"
            or workload.get("function_symbol") != "calkin_wilf_index" or workload.get("abi") != "i64_array_bytes_output"
            or not isinstance(spec, dict) or spec.get("maximum_valid_length") != 1
            or spec.get("maximum_parseable_length") != 2 or spec.get("invalid_input_result") != -1
            or not isinstance(output, dict) or output.get("maximum_bytes") != 16
            or output.get("invalid_input_result") != -1 or output.get("output_error_result") != -2
            or output.get("output_untouched_on_error") is not True
            or not isinstance(workspace, dict) or workspace.get("bytes") != 16):
        issues.append("identity or bounds mismatch")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "c" / f"calkin_wilf_index.{extension}"
        if not path.is_file() or "calkin_wilf_index" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing port or symbol: {language}")
    package = ROOT / "benchmarks/c/calkin_wilf_index"
    for name in ("README.md", "RIGHTS.md", "reference.py"):
        if not (package / name).is_file():
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
        if (not isinstance(values, list) or any(type(v) is not int for v in values)
                or type(length) is not int or type(capacity) is not int or not 0 <= capacity <= 16
                or type(null_in) is not bool or type(null_out) is not bool
                or null_in and (values or not 0 <= length <= 2)
                or not null_in and (length != len(values) or length > 2)):
            issues.append(f"invalid framing: {name}")
            continue
        try:
            wanted = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
        except (KeyError, TypeError, ValueError):
            issues.append(f"invalid output: {name}")
            continue
        args = (values, capacity, null_out, null_in, length)
        if type(wanted[0]) is not int or expected_output(*args) != wanted or independent_output(*args) != wanted:
            issues.append(f"reference disagreement: {name}")
    required = {"root", "left", "right", "alternating", "deep_left", "deep_right", "deep_alternating", "zero", "too_large",
                "trailing_word", "short_output", "null_output", "invalid_before_output", "null_input"}
    if not required <= seen:
        issues.append("missing cases: " + ", ".join(sorted(required - seen)))
    return issues
