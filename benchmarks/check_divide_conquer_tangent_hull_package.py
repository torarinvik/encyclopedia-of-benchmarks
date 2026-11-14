"""Static inventory and fixture checks for the draft tangent-merge hull."""

from pathlib import Path

from workload_json import load_workload
from d.divide_conquer_tangent_hull.primary_oracle import expected_output as primary
from d.divide_conquer_tangent_hull.independent_oracle import expected_output as independent

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/d/divide_conquer_tangent_hull"
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
    if (workload.get("schema_version") != 1 or workload.get("algorithm") != "divide_conquer_tangent_hull"
            or workload.get("function_symbol") != "divide_conquer_tangent_hull"
            or workload.get("abi") != "i64_array_bytes_output"
            or not isinstance(inputs, dict) or not isinstance(output, dict)
            or inputs.get("kind") != "signed_64_bit_integer_array" or inputs.get("point_range") != [3, 32]
            or inputs.get("coordinate_range") != [-1000, 1000] or inputs.get("unique_x") is not True
            or inputs.get("maximum_valid_values") != 65 or inputs.get("maximum_parseable_values") != 66
            or output.get("maximum_output_bytes") != 512 or output.get("no_write_on_error") is not True):
        issues.append("identity or contract mismatch")
    if (not isinstance(workload.get("workspace"), dict) or workload["workspace"].get("bytes") != 512
            or not isinstance(workload.get("measurement"), dict)
            or workload["measurement"].get("comparison_model") != "i64_array_bytes_output_call"):
        issues.append("workspace or measurement mismatch")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "d" / f"divide_conquer_tangent_hull.{extension}"
        if not path.is_file() or "divide_conquer_tangent_hull" not in path.read_text(encoding="utf-8"):
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
                or null_input and (values or not 0 <= length <= 66)
                or not null_input and (length != len(values) or length > 66)):
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
    if not {"triangle", "lower_triangle", "interior_points_unsorted", "duplicate_x", "collinear", "short_output", "null_output",
            "invalid_before_null_output", "null_input", "null_input_at_parser_limit"} <= seen:
        issues.append("missing required fixtures")
    return issues
