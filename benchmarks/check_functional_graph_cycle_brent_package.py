"""Static package inventory and reference checks for Brent cycle finding."""

from pathlib import Path

from workload_json import load_workload
from f.functional_graph_cycle_brent.primary_oracle import expected_output as primary
from f.functional_graph_cycle_brent.independent_oracle import expected_output as independent

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/f/functional_graph_cycle_brent"
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
    if (workload.get("algorithm") != "functional_graph_cycle_brent"
            or workload.get("function_symbol") != "functional_graph_cycle_brent"
            or workload.get("abi") != "i64_array_scalar" or not isinstance(inputs, dict)
            or inputs.get("maximum_valid_values") != 66 or inputs.get("maximum_parseable_values") != 67):
        issues.append("identity or input bounds mismatch")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "f" / f"functional_graph_cycle_brent.{extension}"
        if not path.is_file() or "functional_graph_cycle_brent" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing port or symbol: {language}")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing cases"]
    seen = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid case")
            continue
        if case["id"] in seen:
            issues.append(f"duplicate case: {case['id']}")
        seen.add(case["id"])
        values, length = case.get("input_values"), case.get("input_length")
        null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int or type(null) is not bool
                or null and (values or not 0 <= length <= 67)
                or not null and (length != len(values) or length > 67)):
            issues.append(f"invalid framing: {case['id']}")
            continue
        expected = case.get("expected_result")
        if type(expected) is not int or primary(values, null, length) != expected or independent(values, null, length) != expected:
            issues.append(f"reference disagreement: {case['id']}")
    required = {"self_loop", "tail_and_cycle", "cycle_from_inside", "nonzero_start_with_tail",
                "maximum_tail", "maximum_cycle", "invalid_successor", "invalid_unreachable_successor",
                "trailing_word", "null_input", "null_at_parser_limit"}
    if not required <= seen:
        issues.append("missing cases: " + ", ".join(sorted(required - seen)))
    return issues
