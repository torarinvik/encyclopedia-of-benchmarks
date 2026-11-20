"""Static inventory and fixture checks for symbolic circle intersections."""
import json
from pathlib import Path
from c.circle_circle_intersection_symbolic.reference import expected_output as primary
from c.circle_circle_intersection_symbolic.verifier import expected_output as independent

ROOT = Path(__file__).resolve().parents[1]
NAME = "circle_circle_intersection_symbolic"
PACKAGE = ROOT / "benchmarks/c" / NAME
EXTENSIONS = {"c":"c", "c3":"c3", "cpp":"cpp", "elisa":"elisa", "mojo":"mojo", "nim":"nim", "odin":"odin", "rust":"rs", "v":"v", "zig":"zig"}


def static_issues():
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot load workload: {error}"]
    issues = []
    if (workload.get("algorithm") != NAME or workload.get("function_symbol") != NAME
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("input", {}).get("maximum_valid_length") != 6
            or workload.get("input", {}).get("maximum_parseable_length") != 7
            or workload.get("input", {}).get("center_range") != [-1000, 1000]
            or workload.get("input", {}).get("radius_range") != [1, 1000]
            or workload.get("output", {}).get("maximum_output_bytes") != 56
            or workload.get("workspace", {}).get("bytes") != 56
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_bytes_output_call"):
        issues.append("workload metadata differs from contract")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "c" / f"{NAME}.{extension}"
        if not path.is_file() or NAME not in path.read_text(encoding="utf-8"):
            issues.append(f"missing {language} port or symbol")
    for document in ("README.md", "RIGHTS.md", "reference.py", "verifier.py"):
        if not (PACKAGE / document).is_file():
            issues.append(f"missing {document}")
    rights = PACKAGE / "RIGHTS.md"
    if rights.is_file():
        text = rights.read_text(encoding="utf-8")
        if "https://cp-algorithms.com/geometry/circle-circle-intersection.html" not in text or "CC BY-SA 4.0" not in text:
            issues.append("source link or license missing")
    elisa = ROOT / "elisa/c" / f"{NAME}.elisa"
    if elisa.is_file():
        text = elisa.read_text(encoding="utf-8")
        if "view[i64]" not in text or "mutable view[u8]" not in text:
            issues.append("Elisa port lacks bounded internal views")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing workload cases"]
    seen_ids = set()
    for case in cases:
        if not isinstance(case, dict):
            issues.append("case is not an object")
            continue
        case_id = case.get("id")
        if not isinstance(case_id, str) or not case_id or case_id in seen_ids:
            issues.append("missing or duplicate case id")
        else:
            seen_ids.add(case_id)
        try:
            options = {"capacity":case["output_capacity"], "input_length":case["input_length"],
                       "output_is_null":case.get("output_is_null", False), "input_is_null":case.get("input_is_null", False)}
            expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
            if primary(case["input_values"], **options) != expected or independent(case["input_values"], **options) != expected:
                issues.append(f"fixture mismatch: {case.get('id')}")
        except (KeyError, TypeError, ValueError) as error:
            issues.append(f"invalid fixture: {error}")
    return issues
