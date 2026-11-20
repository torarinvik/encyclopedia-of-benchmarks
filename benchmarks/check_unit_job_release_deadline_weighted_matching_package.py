"""Static source inventory and fixture contract checks for weighted unit jobs."""

from pathlib import Path

from workload_json import load_workload
from u.unit_job_release_deadline_weighted_matching.independent_oracle import expected_output

ROOT = Path(__file__).resolve().parents[1]
NAME = "unit_job_release_deadline_weighted_matching"
PACKAGE = ROOT / "benchmarks" / "u" / NAME
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
    inputs = workload.get("input", {})
    if (workload.get("algorithm") != NAME or workload.get("function_symbol") != NAME
            or workload.get("abi") != "i64_array_scalar" or not isinstance(inputs, dict)
            or inputs.get("maximum_valid_values") != 97 or inputs.get("maximum_parseable_values") != 98):
        issues.append("identity or input bounds mismatch")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "u" / f"{NAME}.{extension}"
        if not path.is_file() or NAME not in path.read_text(encoding="utf-8"):
            issues.append(f"missing port or symbol: {language}")
    for name in ("README.md", "RIGHTS.md", "independent_oracle.py", "brute_oracle.py"):
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
        values, length, null = case.get("input_values"), case.get("input_length"), case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int or type(null) is not bool
                or null and (values or not 0 <= length <= 98)
                or not null and (length != len(values) or length > 98)):
            issues.append(f"invalid framing: {case_id}")
        elif type(case.get("expected_result")) is not int or expected_output(values, null, length) != case["expected_result"]:
            issues.append(f"reference disagreement: {case_id}")
        if case_id == "maximum_frame" and (null or length != 97 or not values or values[0] != 32):
            issues.append("maximum frame must contain 32 jobs")
        if case_id == "null_at_parser_limit" and (not null or length != 98):
            issues.append("null probe must use the parseable-length limit")
    if not {"empty", "reassignment_required", "chain_reassignment", "maximum_frame", "null_input", "null_at_parser_limit"} <= seen:
        issues.append("missing required cases")
    return issues
