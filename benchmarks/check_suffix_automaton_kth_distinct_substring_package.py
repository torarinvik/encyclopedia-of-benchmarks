"""Unexecuted inventory and fixture checks for substring selection."""
from pathlib import Path
from s.suffix_automaton_kth_distinct_substring.reference import expected_output

ROOT = Path(__file__).resolve().parents[1]
NAME = "suffix_automaton_kth_distinct_substring"
EXTENSIONS = {"c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa", "mojo": "mojo",
              "nim": "nim", "odin": "odin", "rust": "rs", "v": "v", "zig": "zig"}


def static_issues(workload):
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    issues = []
    spec, output, workspace = workload.get("input"), workload.get("output"), workload.get("workspace")
    if (workload.get("schema_version") != 1 or workload.get("algorithm") != NAME
            or workload.get("function_symbol") != NAME or workload.get("abi") != "i64_array_bytes_output"
            or not isinstance(spec, dict) or spec.get("maximum_valid_length") != 258
            or spec.get("maximum_parseable_length") != 259 or spec.get("invalid_input_result") != -1
            or not isinstance(output, dict) or output.get("maximum_bytes") != 256
            or output.get("invalid_input_result") != -1 or output.get("output_error_result") != -2
            or output.get("output_untouched_on_error") is not True
            or not isinstance(workspace, dict) or workspace.get("bytes") != 256):
        issues.append("identity or bounds mismatch")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "s" / f"{NAME}.{extension}"
        if not path.is_file() or NAME not in path.read_text(encoding="utf-8"):
            issues.append(f"missing port or symbol: {language}")
    for name in ("README.md", "RIGHTS.md", "reference.py"):
        if not (ROOT / "benchmarks" / "s" / NAME / name).is_file():
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
                or type(length) is not int or type(capacity) is not int or not 0 <= capacity <= 256
                or type(null_in) is not bool or type(null_out) is not bool
                or null_in and (values or not 0 <= length <= 259)
                or not null_in and (length != len(values) or length > 259)):
            issues.append(f"invalid framing: {name}")
            continue
        try:
            wanted = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
        except (KeyError, TypeError, ValueError):
            issues.append(f"invalid output: {name}")
            continue
        if type(wanted[0]) is not int or expected_output(values, capacity, null_out, null_in, length) != wanted:
            issues.append(f"reference disagreement: {name}")
    required = {"singleton", "prefix_order", "last_rank", "repeated", "long_unique_prefix", "long_repeated_prefix", "embedded_zero", "excess_rank",
                "zero_rank", "short_output", "null_output", "invalid_byte", "trailing", "null_input"}
    if not required <= seen:
        issues.append("missing cases: " + ", ".join(sorted(required - seen)))
    return issues
