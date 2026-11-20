"""Static inventory and reference checks for the DSATUR coloring package."""

from pathlib import Path

from workload_json import load_workload
from d.dsatur_greedy_coloring.primary_oracle import expected_output as primary
from d.dsatur_greedy_coloring.independent_oracle import expected_output as independent

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/d/dsatur_greedy_coloring"
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
    inputs = workload.get("input")
    if (workload.get("algorithm") != "dsatur_greedy_coloring"
            or workload.get("function_symbol") != "dsatur_greedy_coloring"
            or workload.get("abi") != "i64_array_scalar" or not isinstance(inputs, dict)
            or inputs.get("maximum_valid_values") != 134
            or inputs.get("maximum_parseable_values") != 135):
        issues.append("identity or input bounds mismatch")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "d" / f"dsatur_greedy_coloring.{extension}"
        if not path.is_file() or "dsatur_greedy_coloring" not in path.read_text(encoding="utf-8"):
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
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate case: {case_id}")
        seen.add(case_id)
        values, length = case.get("input_values"), case.get("input_length")
        null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int or type(null) is not bool
                or null and (values or not 0 <= length <= 135)
                or not null and (length != len(values) or length > 135)):
            issues.append(f"invalid framing: {case_id}")
            continue
        expected = case.get("expected_result")
        first = primary(values, null, length)
        second = independent(values, null, length)
        if type(expected) is not int or first != expected or second != expected:
            issues.append(f"reference disagreement: {case_id}")
            continue
        if not null and expected >= 0:
            n = values[0]
            color_count = expected >> 48
            packed = expected & ((1 << 48) - 1)
            colors = [(packed >> (4 * vertex)) & 15 for vertex in range(n)]
            if color_count != max(colors, default=-1) + 1:
                issues.append(f"packed color count mismatch: {case_id}")
            for edge in range(values[1]):
                u, v = values[2 + 2 * edge:4 + 2 * edge]
                if colors[u] == colors[v]:
                    issues.append(f"improper coloring: {case_id}")
                    break
    required = {
        "single_isolate", "p3_center_by_residual_degree", "triangle",
        "cycle_four_residual_tie", "path_four_dynamic_updates",
        "complete_graph_maximum", "zero_vertices", "self_loop", "duplicate_edge",
        "edge_endpoint_out_of_range", "reversed_edge", "edge_count_above_simple_graph_bound",
        "trailing_word", "null_input", "null_at_parser_limit",
    }
    if not required <= seen:
        issues.append("missing cases: " + ", ".join(sorted(required - seen)))
    return issues
