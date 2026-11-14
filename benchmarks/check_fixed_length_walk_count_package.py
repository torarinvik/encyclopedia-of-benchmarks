"""Draft inventory and fixture checks for exact-length walk counting."""
from pathlib import Path

from f.fixed_length_walk_count.reference import expected, expected_short

ROOT = Path(__file__).resolve().parents[1]
EXTENSIONS = {"c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa", "mojo": "mojo",
              "nim": "nim", "odin": "odin", "rust": "rs", "v": "v", "zig": "zig"}


def static_issues(workload):
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    issues = []
    spec = workload.get("input", {})
    output = workload.get("output", {})
    if (workload.get("schema_version") != 1 or workload.get("algorithm") != "fixed_length_walk_count"
            or workload.get("function_symbol") != "fixed_length_walk_count"
            or workload.get("abi") != "i64_array_scalar" or not isinstance(spec, dict)
            or spec.get("maximum_valid_values") != 260 or spec.get("maximum_parseable_values") != 261
            or spec.get("invalid_result") != -1 or not isinstance(output, dict)
            or output.get("invalid_result") != -1):
        issues.append("metadata does not match the contract")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "f" / f"fixed_length_walk_count.{extension}"
        if not path.is_file() or "fixed_length_walk_count" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing source or symbol: {language}")
    package = ROOT / "benchmarks/f/fixed_length_walk_count"
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
                or null and (values or not 0 <= length <= 261)
                or not null and (length != len(values) or length > 261)):
            issues.append(f"invalid framing: {case_id}")
            continue
        result = expected(None if null else values)
        if type(case.get("expected_result")) is not int or result != case["expected_result"]:
            issues.append(f"reference disagreement: {case_id}")
        if not null and len(values) >= 2 and type(values[1]) is int and 0 <= values[1] <= 64:
            if expected_short(values) != result:
                issues.append(f"short reference disagreement: {case_id}")
    required = {"zero_edge_identity", "zero_edge_distinct", "parallel_edges", "parity_unreachable",
                "complete_graph", "modular_reduction", "dense_four_vertex_modular", "maximum_length_loop", "invalid_multiplicity",
                "trailing_word", "null_input"}
    if not required <= seen:
        issues.append("missing cases: " + ", ".join(sorted(required - seen)))
    return issues
