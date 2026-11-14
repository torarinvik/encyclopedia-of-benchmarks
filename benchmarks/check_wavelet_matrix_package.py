"""Inventory and workload-reference checks for the wavelet matrix."""

from pathlib import Path

from workload_json import load_workload
from w.wavelet_matrix.primary_oracle import expected_output as primary
from w.wavelet_matrix.independent_oracle import expected_output as independent

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/w/wavelet_matrix"
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
    if (workload.get("algorithm") != "wavelet_matrix" or workload.get("function_symbol") != "wavelet_matrix"
            or workload.get("abi") != "i64_array_scalar" or not isinstance(spec, dict)
            or spec.get("maximum_valid_values") != 706 or spec.get("maximum_parseable_values") != 707):
        issues.append("identity or input bounds mismatch")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "w" / f"wavelet_matrix.{extension}"
        if not path.is_file() or "wavelet_matrix" not in path.read_text(encoding="utf-8"):
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
                or (null and (values or not 0 <= length <= 707))
                or (not null and (length != len(values) or length > 707))):
            issues.append(f"invalid framing: {name}")
            continue
        expected = case.get("expected_result")
        if type(expected) is not int or primary(values, null, length) != expected or independent(values, null, length) != expected:
            issues.append(f"reference disagreement: {name}")
    if not {"no_queries", "rank_duplicates", "empty_prefix", "quantile_negative", "range_count", "boundary_range", "boundary_quantile", "ignored_fields", "mixed_queries", "reversed_value_range", "null_input", "null_at_limit"} <= seen:
        issues.append("missing required cases")
    return issues
