"""Static inventory and fixture checks for planted 3-SAT generation."""

from pathlib import Path

from workload_json import load_workload
from p.planted_3sat_clause_generator.primary_oracle import expected_output as primary
from p.planted_3sat_clause_generator.independent_oracle import expected_output as independent

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/p/planted_3sat_clause_generator"
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
    inputs, output = workload.get("input"), workload.get("output")
    if (workload.get("schema_version") != 1 or workload.get("algorithm") != "planted_3sat_clause_generator"
            or workload.get("function_symbol") != "planted_3sat_clause_generator"
            or workload.get("abi") != "i64_array_bytes_output"
            or not isinstance(inputs, dict) or not isinstance(output, dict)
            or inputs.get("kind") != "signed_64_bit_integer_array" or inputs.get("n_range") != [3, 16]
            or inputs.get("m_range") != [0, 32] or inputs.get("maximum_valid_values") != 82
            or inputs.get("maximum_parseable_values") != 83 or output.get("maximum_output_bytes") != 768
            or output.get("no_write_on_error") is not True):
        issues.append("identity or contract mismatch")
    if (not isinstance(workload.get("workspace"), dict) or workload["workspace"].get("bytes") != 768
            or not isinstance(workload.get("measurement"), dict)
            or workload["measurement"].get("comparison_model") != "i64_array_bytes_output_call"):
        issues.append("workspace or measurement mismatch")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "p" / f"planted_3sat_clause_generator.{extension}"
        if not path.is_file() or "planted_3sat_clause_generator" not in path.read_text(encoding="utf-8"):
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
        values, length, capacity = case.get("input_values"), case.get("input_length"), case.get("output_capacity")
        null_input, null_output = case.get("input_is_null", False), case.get("output_is_null", False)
        if (not isinstance(values, list) or type(length) is not int or type(capacity) is not int
                or capacity < 0 or type(null_input) is not bool or type(null_output) is not bool
                or null_input and (values or not 0 <= length <= 83)
                or not null_input and (length != len(values) or length > 83)):
            issues.append(f"invalid framing: {case_id}")
            continue
        try:
            expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
        except (KeyError, TypeError, ValueError):
            issues.append(f"invalid output: {case_id}")
            continue
        if type(expected[0]) is not int:
            issues.append(f"invalid result type: {case_id}")
            continue
        args = (values, capacity, null_output, null_input, length)
        if primary(*args) != expected or independent(*args) != expected:
            issues.append(f"reference disagreement: {case_id}")
    if not {"single_clause", "last_subset_all_true", "empty_formula_null_output", "invalid_rank", "invalid_mask",
            "invalid_assignment", "short_output", "null_output", "null_input", "null_input_at_parser_limit"} <= seen:
        issues.append("missing required fixtures")
    return issues
