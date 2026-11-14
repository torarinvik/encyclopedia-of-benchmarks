"""Draft inventory and fixture checks for proper tree cost coloring."""
from pathlib import Path

from t.tree_min_cost_proper_coloring.reference import expected, brute_small

ROOT = Path(__file__).resolve().parents[1]
EXTENSIONS = {"c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa", "mojo": "mojo",
              "nim": "nim", "odin": "odin", "rust": "rs", "v": "v", "zig": "zig"}


def static_issues(workload):
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    issues = []
    spec, output = workload.get("input", {}), workload.get("output", {})
    if (workload.get("schema_version") != 1 or workload.get("algorithm") != "tree_min_cost_proper_coloring"
            or workload.get("function_symbol") != "tree_min_cost_proper_coloring"
            or workload.get("abi") != "i64_array_scalar" or not isinstance(spec, dict)
            or spec.get("maximum_valid_values") != 1089 or spec.get("maximum_parseable_values") != 1090
            or spec.get("invalid_result") != -1 or not isinstance(output, dict)
            or output.get("invalid_result") != -1 or output.get("infeasible_result") != -2):
        issues.append("metadata does not match the contract")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "t" / f"tree_min_cost_proper_coloring.{extension}"
        if not path.is_file() or "tree_min_cost_proper_coloring" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing source or symbol: {language}")
    package = ROOT / "benchmarks/t/tree_min_cost_proper_coloring"
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
                or null and (values or not 0 <= length <= 1090)
                or not null and (length != len(values) or length > 1090)):
            issues.append(f"invalid framing: {case_id}")
            continue
        result = expected(None if null else values)
        if type(case.get("expected_result")) is not int or result != case["expected_result"]:
            issues.append(f"reference disagreement: {case_id}")
        if not null and len(values) >= 2 and type(values[0]) is int and type(values[1]) is int and 1 <= values[0] <= 5 and 1 <= values[1] <= 4:
            if brute_small(values) != result:
                issues.append(f"brute-force disagreement: {case_id}")
    required = {"single_vertex", "shared_sibling_color", "equal_child_minima", "chain",
                "one_color_impossible", "invalid_before_infeasible", "invalid_parent", "trailing_word", "null_input"}
    if not required <= seen:
        issues.append("missing cases: " + ", ".join(sorted(required - seen)))
    return issues
