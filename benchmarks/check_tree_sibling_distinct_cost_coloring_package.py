"""Draft inventory and fixture checks; not executed."""
from pathlib import Path

from t.tree_sibling_distinct_cost_coloring.reference import expected, brute_small

ROOT = Path(__file__).resolve().parents[1]
EXTENSIONS = {"c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa", "mojo": "mojo",
              "nim": "nim", "odin": "odin", "rust": "rs", "v": "v", "zig": "zig"}
NAME = "tree_sibling_distinct_cost_coloring"


def static_issues(workload):
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    issues = []
    spec, output = workload.get("input"), workload.get("output")
    if (workload.get("schema_version") != 1 or workload.get("algorithm") != NAME
            or workload.get("function_symbol") != NAME or workload.get("abi") != "i64_array_scalar"
            or not isinstance(spec, dict) or spec.get("maximum_valid_values") != 353
            or spec.get("maximum_parseable_values") != 354 or spec.get("invalid_result") != -1
            or not isinstance(output, dict) or output.get("invalid_result") != -1
            or output.get("infeasible_result") != -2):
        issues.append("metadata does not match the contract")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "t" / f"{NAME}.{extension}"
        if not path.is_file() or NAME not in path.read_text(encoding="utf-8"):
            issues.append(f"missing source or symbol: {language}")
    package = ROOT / "benchmarks" / "t" / NAME
    for filename in ("README.md", "RIGHTS.md", "reference.py"):
        if not (package / filename).is_file():
            issues.append(f"missing package file: {filename}")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing cases"]
    ids = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid case")
            continue
        name = case["id"]
        if name in ids:
            issues.append(f"duplicate case: {name}")
        ids.add(name)
        values, length, null = case.get("input_values"), case.get("input_length"), case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int or type(null) is not bool
                or (null and (values or not 0 <= length <= 354))
                or (not null and (length != len(values) or length > 354))):
            issues.append(f"invalid framing: {name}")
            continue
        if type(case.get("expected_result")) is not int or expected(None if null else values) != case["expected_result"]:
            issues.append(f"reference disagreement: {name}")
        if (not null and len(values) >= 2 and type(values[0]) is int and type(values[1]) is int
                and 1 <= values[0] <= 5 and 1 <= values[1] <= 4):
            if brute_small(values) != expected(values):
                issues.append(f"exhaustive reference disagreement: {name}")
    required = {"single_vertex", "single_vertex_one_color", "siblings_need_distinct_colors", "assignment_requires_exchange",
                "two_color_chain", "grandparent_color_may_repeat", "saturated_four_color_star",
                "two_color_star_infeasible", "invalid_before_infeasible",
                "invalid_parent", "trailing_word", "null_input", "null_input_at_parse_limit"}
    if not required.issubset(ids):
        issues.append("required boundary cases are missing")
    return issues
