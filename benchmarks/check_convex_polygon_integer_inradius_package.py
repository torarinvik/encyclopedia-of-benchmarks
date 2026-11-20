"""Inventory and fixture checks for the unexecuted inradius drafts."""
from pathlib import Path
from workload_json import load_workload
from c.convex_polygon_integer_inradius.reference import expected_result

ROOT = Path(__file__).resolve().parents[1]
NAME = "convex_polygon_integer_inradius"
PACKAGE = ROOT / "benchmarks/c" / NAME
EXTENSIONS = {"c":"c", "c3":"c3", "cpp":"cpp", "elisa":"elisa", "mojo":"mojo", "nim":"nim", "odin":"odin", "rust":"rs", "v":"v", "zig":"zig"}


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
    if (workload.get("schema_version") != 1 or workload.get("algorithm") != NAME
            or workload.get("function_symbol") != NAME or workload.get("abi") != "i64_array_scalar"
            or inputs.get("maximum_valid_values") != 37 or inputs.get("maximum_parseable_values") != 38
            or inputs.get("constraint_count_range") != [0, 12]
            or inputs.get("normal_range") != [-15, 15]
            or inputs.get("offset_range") != [-128, 128]
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"):
        issues.append("identity or input bounds mismatch")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "c" / f"{NAME}.{extension}"
        if not path.is_file() or NAME not in path.read_text(encoding="utf-8"):
            issues.append(f"missing port or symbol: {language}")
    for document in ("README.md", "RIGHTS.md", "reference.py"):
        if not (PACKAGE / document).is_file():
            issues.append(f"missing {document}")
    rights = PACKAGE / "RIGHTS.md"
    if rights.is_file():
        text = rights.read_text(encoding="utf-8")
        if "https://cp-algorithms.com/geometry/halfplane-intersection.html" not in text or "CC BY-SA 4.0" not in text:
            issues.append("source or license missing from rights note")
    elisa = ROOT / "elisa/c" / f"{NAME}.elisa"
    if elisa.is_file() and "view[i64]" not in elisa.read_text(encoding="utf-8"):
        issues.append("Elisa implementation lacks bounded internal views")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing workload cases"]
    seen = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid case")
            continue
        if case["id"] in seen:
            issues.append(f"duplicate case id: {case['id']}")
        seen.add(case["id"])
        values, length, null = case.get("input_values"), case.get("input_length"), case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int or type(null) is not bool
                or null and (values or not 0 <= length <= 38)
                or not null and (length != len(values) or length > 38)):
            issues.append(f"invalid framing: {case['id']}")
            continue
        if type(case.get("expected_result")) is not int or expected_result(values, null) != case["expected_result"]:
            issues.append(f"reference mismatch: {case['id']}")
    required = {"implicit-square", "fractional-radius-floor", "zero-area-segment",
                "single-point", "empty-region", "duplicate-direction-tightest-later",
                "duplicate-direction-tightest-earlier", "null-input-at-limit"}
    if not required <= seen:
        issues.append("missing contract cases: " + ", ".join(sorted(required - seen)))
    return issues
