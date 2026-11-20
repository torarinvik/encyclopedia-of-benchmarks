"""Draft inventory and fixture checks; intentionally not executed."""
from pathlib import Path

from t.tree_minimum_path_partition.reference import expected, brute_small, parse

ROOT = Path(__file__).resolve().parents[1]
EXTENSIONS = {"c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa", "mojo": "mojo",
              "nim": "nim", "odin": "odin", "rust": "rs", "v": "v", "zig": "zig"}


def static_issues(workload):
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    issues = []
    spec, output = workload.get("input"), workload.get("output")
    if (workload.get("schema_version") != 1 or workload.get("algorithm") != "tree_minimum_path_partition"
            or workload.get("function_symbol") != "tree_minimum_path_partition"
            or workload.get("abi") != "i64_array_scalar" or not isinstance(spec, dict)
            or spec.get("maximum_valid_values") != 64 or spec.get("maximum_parseable_values") != 65
            or spec.get("invalid_result") != -1 or not isinstance(output, dict) or output.get("invalid_result") != -1):
        issues.append("metadata does not match the contract")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "t" / f"tree_minimum_path_partition.{extension}"
        if not path.is_file() or "tree_minimum_path_partition" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing source or symbol: {language}")
    package = ROOT / "benchmarks/t/tree_minimum_path_partition"
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
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate case: {case_id}")
        seen.add(case_id)
        values, length, null = case.get("input_values"), case.get("input_length"), case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int or type(null) is not bool
                or null and (values or not 0 <= length <= 65)
                or not null and (length != len(values) or length > 65)):
            issues.append(f"invalid framing: {case_id}")
            continue
        result = expected(None if null else values)
        if type(case.get("expected_result")) is not int or result != case["expected_result"]:
            issues.append(f"reference disagreement: {case_id}")
        parsed = None if null else parse(values)
        if parsed is not None and parsed[0] <= 16 and brute_small(values) != result:
            issues.append(f"brute-force disagreement: {case_id}")
    required = {"singleton", "single_edge", "three_vertex_path", "five_vertex_star", "balanced_binary",
                "path_with_side_leaf", "full_path", "full_star", "invalid_parent", "negative_parent", "zero_vertices",
                "too_many_vertices", "trailing_word", "null_input"}
    if not required <= seen:
        issues.append("missing cases: " + ", ".join(sorted(required - seen)))
    return issues
