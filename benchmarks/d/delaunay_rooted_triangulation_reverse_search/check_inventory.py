"""Static package/workload checks only; references and ports are never invoked."""

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "delaunay_rooted_triangulation_reverse_search"
SOURCE_URL = "https://doi.org/10.1007/978-1-4939-2864-4_729"
PORTS = (
    "c/d/delaunay_rooted_triangulation_reverse_search.c",
    "c3/d/delaunay_rooted_triangulation_reverse_search.c3",
    "cpp/d/delaunay_rooted_triangulation_reverse_search.cpp",
    "elisa/d/delaunay_rooted_triangulation_reverse_search.elisa",
    "mojo/d/delaunay_rooted_triangulation_reverse_search.mojo",
    "nim/d/delaunay_rooted_triangulation_reverse_search.nim",
    "odin/d/delaunay_rooted_triangulation_reverse_search.odin",
    "rust/d/delaunay_rooted_triangulation_reverse_search.rs",
    "v/d/delaunay_rooted_triangulation_reverse_search.v",
    "zig/d/delaunay_rooted_triangulation_reverse_search.zig",
)


def static_issues() -> list[str]:
    issues = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package artifact: {error}"]

    if (workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("workload identity or ABI differs from package")
    if (inventory.get("algorithm") != SYMBOL or inventory.get("symbol") != SYMBOL
            or inventory.get("abi") != "i64_array_scalar"
            or inventory.get("source_url") != SOURCE_URL):
        issues.append("inventory identity, ABI, or source differs from package")
    if inventory.get("ports") != list(PORTS):
        issues.append("inventory does not list the ten expected ports")
    if (inventory.get("max_valid_input_length") != 28
            or inventory.get("max_parseable_input_length") != 29
            or inventory.get("workspace_bytes") != 4096):
        issues.append("inventory bounds or workspace differ from contract")
    if SOURCE_URL not in workload.get("source", {}).get("url", ""):
        issues.append("workload source citation is missing")
    if SOURCE_URL not in readme or SOURCE_URL not in rights:
        issues.append("README or rights omits the chapter citation")
    measurement = workload.get("measurement", {})
    if any(type(measurement.get(key)) is not int or measurement[key] <= 0
           for key in ("sample_count", "warmup_rounds", "repetitions_per_sample")):
        issues.append("measurement defaults are missing or invalid")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        issues.append("workload cases must be a nonempty list")
    else:
        seen = set()
        for case in cases:
            if not isinstance(case, dict):
                issues.append("workload case is not an object")
                continue
            case_id = case.get("id")
            values = case.get("input_values")
            if not isinstance(case_id, str) or case_id in seen:
                issues.append("workload case IDs are not unique strings")
            else:
                seen.add(case_id)
            if (not isinstance(values, list) or type(case.get("expected_result")) is not int
                    or any(type(value) is not int for value in values)):
                issues.append(f"workload case has malformed values: {case_id}")
                continue
            if len(values) > 29:
                issues.append(f"workload case exceeds parseable length: {case_id}")
        maximum = next((case for case in cases if isinstance(case, dict)
                        and case.get("id") == "maximum-eight-vertex-set"), None)
        trailing = next((case for case in cases if isinstance(case, dict)
                         and case.get("id") == "trailing-word-parse-bound"), None)
        if not isinstance(maximum, dict) or len(maximum.get("input_values", [])) != 28:
            issues.append("maximum fixture does not exercise the 28-word frame")
        if (not isinstance(trailing, dict) or len(trailing.get("input_values", [])) != 29
                or not isinstance(maximum, dict)
                or trailing["input_values"][:-1] != maximum.get("input_values", [])):
            issues.append("trailing fixture does not extend the maximum frame")

    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing language port: {relative}")
            continue
        try:
            source = path.read_text(encoding="utf-8")
        except OSError as error:
            issues.append(f"cannot read language port {relative}: {error}")
            continue
        if SYMBOL not in source:
            issues.append(f"language port omits symbol: {relative}")
        if relative not in readme:
            issues.append(f"README omits port path: {relative}")
    return issues
