"""Source inventory and fixture/reference checks for the Fenwick sweep."""

from pathlib import Path

from workload_json import load_workload
from o.offline_range_distinct_fenwick.primary_oracle import expected_output as primary
from o.offline_range_distinct_fenwick.independent_oracle import expected_output as independent

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/o/offline_range_distinct_fenwick"
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
    if (workload.get("algorithm") != "offline_range_distinct_fenwick"
            or workload.get("function_symbol") != "offline_range_distinct_fenwick"
            or workload.get("abi") != "i64_array_scalar" or not isinstance(inputs, dict)
            or inputs.get("maximum_valid_values") != 194 or inputs.get("maximum_parseable_values") != 195):
        issues.append("identity or input bounds mismatch")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "o" / f"offline_range_distinct_fenwick.{extension}"
        if not path.is_file() or "offline_range_distinct_fenwick" not in path.read_text(encoding="utf-8"):
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
                or null and (values or not 0 <= length <= 195)
                or not null and (length != len(values) or length > 195)):
            issues.append(f"invalid framing: {case_id}")
            continue
        expected = case.get("expected_result")
        if type(expected) is not int or primary(values, null, length) != expected or independent(values, null, length) != expected:
            issues.append(f"reference disagreement: {case_id}")
    required = {"mixed_repeats", "empty_ranges", "all_equal", "no_queries", "maximum_frame", "invalid_value", "reversed_range",
                "range_past_end", "trailing_word", "null_input", "null_at_parser_limit"}
    if not required <= seen:
        issues.append("missing cases: " + ", ".join(sorted(required - seen)))
    return issues
