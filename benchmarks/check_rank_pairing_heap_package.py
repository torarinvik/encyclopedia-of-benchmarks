"""Static inventory and reference checks for the Type-1 rank-pairing heap."""

from pathlib import Path

from workload_json import load_workload
from r.rank_pairing_heap.primary_oracle import expected_output as primary
from r.rank_pairing_heap.independent_oracle import expected_output as independent

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/r/rank_pairing_heap"
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
    if (workload.get("algorithm") != "rank_pairing_heap"
            or workload.get("function_symbol") != "rank_pairing_heap"
            or workload.get("abi") != "i64_array_scalar" or not isinstance(inputs, dict)
            or inputs.get("maximum_valid_values") != 193
            or inputs.get("maximum_parseable_values") != 194):
        issues.append("identity or input bounds mismatch")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "r" / f"rank_pairing_heap.{extension}"
        if not path.is_file() or "rank_pairing_heap" not in path.read_text(encoding="utf-8"):
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
                or null and (values or not 0 <= length <= 194)
                or not null and (length != len(values) or length > 194)):
            issues.append(f"invalid framing: {case_id}")
            continue
        expected = case.get("expected_result")
        if (type(expected) is not int or primary(values, null, length) != expected
                or independent(values, null, length) != expected):
            issues.append(f"reference disagreement: {case_id}")
    required = {
        "insert_find_delete_min", "decrease_new_root", "type1_rank_repair_after_cut",
        "equal_keys_root_tie", "reuse_deleted_item_id", "key_upper_bound",
        "empty_trace", "maximum_frame", "duplicate_active_item", "decrease_not_strict",
        "delete_min_empty", "find_min_empty", "unused_operand", "key_above_limit",
        "trailing_word", "null_input", "null_at_parser_limit",
    }
    if not required <= seen:
        issues.append("missing cases: " + ", ".join(sorted(required - seen)))
    return issues
