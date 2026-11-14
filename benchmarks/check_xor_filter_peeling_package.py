"""Inventory and workload-reference checks for XOR filter peeling."""

from pathlib import Path

from workload_json import load_workload
from x.xor_filter_peeling.primary_oracle import expected_output as primary
from x.xor_filter_peeling.independent_oracle import expected_output as independent

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/x/xor_filter_peeling"
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
    spec = workload.get("input")
    if (workload.get("algorithm") != "xor_filter_peeling" or workload.get("function_symbol") != "xor_filter_peeling"
            or workload.get("abi") != "i64_array_scalar" or not isinstance(spec, dict)
            or spec.get("maximum_valid_values") != 259 or spec.get("maximum_parseable_values") != 260):
        issues.append("identity or input bounds mismatch")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "x" / f"xor_filter_peeling.{extension}"
        if not path.is_file() or "xor_filter_peeling" not in path.read_text(encoding="utf-8"):
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
        name = case["id"]
        if name in seen:
            issues.append(f"duplicate case: {name}")
        seen.add(name)
        values = case.get("input_values")
        null = case.get("input_is_null", False)
        length = case.get("input_length", len(values) if isinstance(values, list) else None)
        if (not isinstance(values, list) or type(null) is not bool or type(length) is not int
                or (null and (values or not 0 <= length <= 260))
                or (not null and (length != len(values) or length > 260))):
            issues.append(f"invalid framing: {name}")
            continue
        expected = case.get("expected_result")
        if type(expected) is not int or primary(values, null, length) != expected or independent(values, null, length) != expected:
            issues.append(f"reference disagreement: {name}")
    if not {"empty", "empty_filter_queries", "one_edge", "shared_slots", "assigned_false_positive", "partial_peel_then_cycle", "permuted_slots", "cycle_failure", "bad_query_precedes_failure", "null_input", "null_at_limit"} <= seen:
        issues.append("missing required cases")
    return issues
