"""Static inventory and oracle agreement checks; intentionally not executed."""

from pathlib import Path

from workload_json import load_workload
from m.manhattan_mst_candidate_edge_reduction.primary_oracle import expected_result as primary
from m.manhattan_mst_candidate_edge_reduction.independent_oracle import expected_result as independent

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/m/manhattan_mst_candidate_edge_reduction"
EXTENSIONS = {"c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
              "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
              "v": "v", "zig": "zig"}


def static_issues(workload=None):
    if workload is None:
        try:
            workload = load_workload(PACKAGE / "workload.json")
        except (OSError, ValueError) as error:
            return [f"cannot read workload: {error}"]
    if (not isinstance(workload, dict)
            or workload.get("algorithm") != "manhattan_mst_candidate_edge_reduction"
            or workload.get("function_symbol") != "manhattan_mst_candidate_edge_reduction"
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("input", {}).get("maximum_valid_length") != 63
            or workload.get("input", {}).get("maximum_parseable_length") != 64
            or workload.get("workspace", {}).get("bytes") != 8192):
        return ["identity or input bounds mismatch"]

    issues = []
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "m" / f"manhattan_mst_candidate_edge_reduction.{extension}"
        if not path.is_file() or "manhattan_mst_candidate_edge_reduction" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing port or symbol: {language}")
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "primary_oracle.py", "independent_oracle.py"):
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
        values = case.get("input_values")
        length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int or type(is_null) is not bool
                or (is_null and (values or not 0 <= length <= 64))
                or (not is_null and (length != len(values) or length > 64))):
            issues.append(f"invalid framing: {case_id}")
            continue
        expected = case.get("expected_result")
        if (type(expected) is not int
                or primary(values, is_null, length) != expected
                or independent(values, is_null, length) != expected):
            issues.append(f"oracle disagreement: {case_id}")

    required = {"empty_point_set", "singleton", "two_points", "general_four_point_set",
                "diagonal_chain", "negative_coordinate_triangle", "equal_distance_tie",
                "duplicate_x_coordinate", "duplicate_y_coordinate", "trailing_word", "null_input"}
    if not required <= seen:
        issues.append("missing cases: " + ", ".join(sorted(required - seen)))
    return issues
