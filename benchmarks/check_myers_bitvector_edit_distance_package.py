"""Unexecuted inventory and fixture checks for Myers edit distance."""
from pathlib import Path

from m.myers_bitvector_edit_distance.reference import expected

ROOT = Path(__file__).resolve().parents[1]
EXTENSIONS = {"c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa", "mojo": "mojo",
              "nim": "nim", "odin": "odin", "rust": "rs", "v": "v", "zig": "zig"}


def static_issues(workload):
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    issues = []
    spec, output = workload.get("input"), workload.get("output")
    if (workload.get("schema_version") != 1 or workload.get("algorithm") != "myers_bitvector_edit_distance"
            or workload.get("function_symbol") != "myers_bitvector_edit_distance" or workload.get("abi") != "i64_array_scalar"
            or not isinstance(spec, dict) or spec.get("maximum_valid_values") != 514
            or spec.get("maximum_parseable_values") != 515 or spec.get("invalid_result") != -1
            or not isinstance(output, dict) or output.get("invalid_result") != -1):
        issues.append("metadata does not match the contract")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "m" / f"myers_bitvector_edit_distance.{extension}"
        if not path.is_file() or "myers_bitvector_edit_distance" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing source or symbol: {language}")
    package = ROOT / "benchmarks/m/myers_bitvector_edit_distance"
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
                or null and (values or not 0 <= length <= 515)
                or not null and (length != len(values) or length > 515)):
            issues.append(f"invalid framing: {case_id}")
            continue
        result = expected(None if null else values)
        if type(case.get("expected_result")) is not int or result != case["expected_result"]:
            issues.append(f"reference disagreement: {case_id}")
    required = {"empty", "empty_left", "empty_right", "identical", "substitute", "insert_delete",
                "boundary_63", "boundary_64", "boundary_65", "boundary_127", "boundary_128",
                "boundary_129", "boundary_191", "boundary_192", "boundary_193", "boundary_256",
                "full_disjoint", "full_identical", "insert_at_word_boundary", "delete_at_word_boundary",
                "invalid_symbol", "invalid_negative_symbol", "oversize_dimension", "negative_length", "trailing_word", "null_input"}
    if not required <= seen:
        issues.append("missing cases: " + ", ".join(sorted(required - seen)))
    return issues
