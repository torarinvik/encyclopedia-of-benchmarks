"""Static inventory and workload-reference checks for backward oracle matching."""

from pathlib import Path

from workload_json import load_workload
from b.backward_oracle_match.primary_oracle import expected_output as primary
from b.backward_oracle_match.independent_oracle import expected_output as independent

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/b/backward_oracle_match"
NAME = "backward_oracle_match"
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
    if (workload.get("algorithm") != NAME or workload.get("function_symbol") != NAME
            or workload.get("abi") != "i64_array_scalar" or not isinstance(spec, dict)
            or spec.get("maximum_valid_values") != 4161 or spec.get("maximum_parseable_values") != 4162):
        issues.append("identity or input bounds mismatch")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "b" / f"{NAME}.{extension}"
        if not path.is_file() or NAME not in path.read_text(encoding="utf-8"):
            issues.append(f"missing port or symbol: {language}")
    for filename in ("README.md", "RIGHTS.md", "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package file: {filename}")
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
                or (null and (values or not 0 <= length <= 4162))
                or (not null and (length != len(values) or length > 4162))):
            issues.append(f"invalid framing: {name}")
            continue
        expected = case.get("expected_result")
        if type(expected) is not int or primary(values, null, length) != expected or independent(values, null, length) != expected:
            issues.append(f"reference disagreement: {name}")
    if not {"empty_pattern", "first_overlap", "late_overlap", "skip_then_match", "repeated_prefix", "long_repeated_prefix", "single_character_late", "absent", "pattern_limit", "negative_length", "text_limit", "null_input", "null_maximum"} <= seen:
        issues.append("missing required cases")
    return issues
