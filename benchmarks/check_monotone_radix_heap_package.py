"""Source inventory and fixture/reference checks for monotone radix heaps."""

from pathlib import Path

from workload_json import load_workload
from m.monotone_radix_heap.primary_oracle import expected_output as primary
from m.monotone_radix_heap.independent_oracle import expected_output as independent

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/m/monotone_radix_heap"
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
    if (workload.get("algorithm") != "monotone_radix_heap"
            or workload.get("function_symbol") != "monotone_radix_heap"
            or workload.get("abi") != "i64_array_scalar" or not isinstance(inputs, dict)
            or inputs.get("maximum_valid_values") != 129 or inputs.get("maximum_parseable_values") != 130):
        issues.append("identity or input bounds mismatch")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "m" / f"monotone_radix_heap.{extension}"
        if not path.is_file() or "monotone_radix_heap" not in path.read_text(encoding="utf-8"):
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
                or null and (values or not 0 <= length <= 130)
                or not null and (length != len(values) or length > 130)):
            issues.append(f"invalid framing: {case_id}")
            continue
        expected = case.get("expected_result")
        if type(expected) is not int or primary(values, null, length) != expected or independent(values, null, length) != expected:
            issues.append(f"reference disagreement: {case_id}")
    required = {"redistribution_and_duplicates", "key_boundaries", "reinsertion_at_last", "high_bit_boundary",
                "empty_trace", "maximum_frame", "below_last",
                "pop_empty", "pop_argument", "key_too_large", "trailing_word", "null_input", "null_at_parser_limit"}
    if not required <= seen:
        issues.append("missing cases: " + ", ".join(sorted(required-seen)))
    return issues
