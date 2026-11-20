"""Package inventory and independent fixture checks for incremental clipping."""
import json
from pathlib import Path

from half_plane_intersection_verifier_oracle import expected_output, verify_output

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/h/half_plane_intersection_incremental_clipping"
NAME = "half_plane_intersection_incremental_clipping"
EXTENSIONS = {"c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa", "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs", "v": "v", "zig": "zig"}


def static_issues() -> list[str]:
    issues = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if workload.get("algorithm") != NAME or workload.get("function_symbol") != NAME:
        issues.append("algorithm or symbol mismatch")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("ABI mismatch")
    if (workload.get("input", {}).get("constraint_count_range") != [0, 12]
            or workload.get("input", {}).get("maximum_valid_length") != 37
            or workload.get("input", {}).get("maximum_parseable_length") != 38
            or workload.get("output", {}).get("maximum_vertices") != 16
            or workload.get("output", {}).get("maximum_output_bytes") != 520
            or workload.get("workspace", {}).get("bytes") != 8192):
        issues.append("workload bounds differ from the clipping contract")
    if workload.get("measurement", {}).get("comparison_model") != "i64_array_bytes_output_call":
        issues.append("measurement model mismatch")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "h" / f"{NAME}.{extension}"
        if not path.is_file() or NAME not in path.read_text(encoding="utf-8"):
            issues.append(f"missing {language} implementation or symbol")
    for name in ("README.md", "RIGHTS.md", "reference.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing {name}")
    rights_path = PACKAGE / "RIGHTS.md"
    if rights_path.is_file():
        rights = rights_path.read_text(encoding="utf-8")
        if ("https://cp-algorithms.com/geometry/halfplane-intersection.html" not in rights
                or "CC BY-SA 4.0" not in rights):
            issues.append("missing source or license in rights note")
    elisa_path = ROOT / "elisa/h" / f"{NAME}.elisa"
    if elisa_path.is_file():
        source = elisa_path.read_text(encoding="utf-8")
        if "view[i64]" not in source or "mutable view[u8]" not in source:
            issues.append("Elisa implementation must use bounded internal views")
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
        options = {"capacity": case.get("output_capacity"), "output_is_null": case.get("output_is_null", False),
                   "input_is_null": case.get("input_is_null", False), "input_length": case.get("input_length")}
        try:
            expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
            actual = expected_output(case["input_values"], **options)
            if actual != expected or not verify_output(case["input_values"], *actual, **options):
                issues.append(f"fixture mismatch: {case.get('id')}")
        except (KeyError, TypeError, ValueError) as error:
            issues.append(f"invalid fixture: {error}")
    return issues
