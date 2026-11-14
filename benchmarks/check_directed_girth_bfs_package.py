"""Static inventory and fixture checks for directed-girth benchmark drafts."""

from pathlib import Path

from workload_json import load_workload
from d.directed_girth_bfs.primary_oracle import expected_output as primary
from d.directed_girth_bfs.independent_oracle import expected_output as independent

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/d/directed_girth_bfs"
EXTENSIONS = {"c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
              "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
              "v": "v", "zig": "zig"}


def static_issues(workload=None):
    issues = []
    if workload is None:
        try:
            workload = load_workload(PACKAGE / "workload.json")
        except (OSError, ValueError) as error:
            return [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    inputs = workload.get("input", {})
    if not isinstance(inputs, dict):
        return ["input metadata must be an object"]
    if (workload.get("schema_version") != 1 or workload.get("algorithm") != "directed_girth_bfs"
            or workload.get("function_symbol") != "directed_girth_bfs"
            or workload.get("abi") != "i64_array_scalar"
            or inputs.get("maximum_valid_values") != 130
            or inputs.get("maximum_parseable_values") != 131):
        issues.append("identity or input bounds mismatch")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "d" / f"directed_girth_bfs.{extension}"
        if not path.is_file() or "directed_girth_bfs" not in path.read_text(encoding="utf-8"):
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
            issues.append(f"duplicate case id: {case['id']}")
        seen.add(case["id"])
        values = case.get("input_values")
        length = case.get("input_length")
        null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int or type(null) is not bool
                or null and (values or not 0 <= length <= 131)
                or not null and (length != len(values) or length > 131)):
            issues.append(f"invalid framing: {case['id']}")
            continue
        expected = case.get("expected_result")
        if type(expected) is not int or primary(values, null, length) != expected or independent(values, null, length) != expected:
            issues.append(f"reference disagreement: {case['id']}")
    required = {"empty_edges", "self_loop", "acyclic", "directed_triangle", "shorter_disconnected_cycle",
                "parallel_edges", "maximum_length_cycle", "maximum_edge_count", "invalid_vertex", "trailing_word",
                "null_input", "null_input_at_parser_limit"}
    if not required <= seen:
        issues.append("missing cases: " + ", ".join(sorted(required - seen)))
    return issues
