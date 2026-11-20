"""Unexecuted source inventory and workload checks for recursive contraction."""
from pathlib import Path
from k.karger_stein_recursive_contraction.reference import expected_result

ROOT = Path(__file__).resolve().parents[1]
NAME = "karger_stein_recursive_contraction"
EXTENSIONS = {"c":"c", "cpp":"cpp", "c3":"c3", "elisa":"elisa", "mojo":"mojo",
              "nim":"nim", "odin":"odin", "rust":"rs", "v":"v", "zig":"zig"}


def static_issues(workload):
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    spec = workload.get("input")
    if (workload.get("schema_version") != 1 or workload.get("algorithm") != NAME
            or workload.get("function_symbol") != NAME or workload.get("abi") != "i64_array_scalar"
            or not isinstance(spec, dict) or spec.get("maximum_input_values") != 131
            or spec.get("maximum_parseable_values") != 132):
        return ["identity or bounds mismatch"]
    issues = []
    for language, ext in EXTENSIONS.items():
        path = ROOT / language / "k" / f"{NAME}.{ext}"
        if not path.is_file() or NAME not in path.read_text(encoding="utf-8"):
            issues.append(f"missing source or symbol: {language}")
    cases = workload.get("cases")
    if not isinstance(cases, list):
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
        values, length = case.get("input_values"), case.get("input_length")
        null, result = case.get("input_is_null", False), case.get("expected_result")
        if (not isinstance(values, list) or any(type(v) is not int for v in values)
                or type(length) is not int or type(null) is not bool or type(result) is not int
                or (null and (values or not 0 <= length <= 132))
                or (not null and (length != len(values) or length > 132))):
            issues.append(f"invalid framing: {name}")
            continue
        if (-1 if null else expected_result(values)) != result:
            issues.append(f"reference disagreement: {name}")
    required = {"single_edge", "parallel_edges", "base_triangle", "seven_cycle_two_branches",
                "eight_cycle_nested_branches", "seven_vertex_complete_graph", "second_branch_preserves_bridge",
                "both_branches_contract_bridge", "negative_rank_second_branch", "rank_too_large",
                "short_tape", "extra_tape", "disconnected", "self_loop", "trailing", "null_input", "null_input_limit"}
    if not required <= seen:
        issues.append("missing cases: " + ", ".join(sorted(required - seen)))
    return issues
