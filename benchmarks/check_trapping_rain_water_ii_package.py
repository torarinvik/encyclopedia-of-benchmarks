"""Static inventory and fixture review for 2-D trapped-rainwater ports."""

from __future__ import annotations

import json
from pathlib import Path

from trapping_rain_water_ii_oracle import expected_result as primary_result
from trapping_rain_water_ii_verifier_oracle import expected_result as independent_result

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/t/trapping_rain_water_ii"
PORTS = {
    "c": ROOT / "c/t/trapping_rain_water_ii.c",
    "c3": ROOT / "c3/t/trapping_rain_water_ii.c3",
    "cpp": ROOT / "cpp/t/trapping_rain_water_ii.cpp",
    "elisa": ROOT / "elisa/t/trapping_rain_water_ii.elisa",
    "mojo": ROOT / "mojo/t/trapping_rain_water_ii.mojo",
    "nim": ROOT / "nim/t/trapping_rain_water_ii.nim",
    "odin": ROOT / "odin/t/trapping_rain_water_ii.odin",
    "rust": ROOT / "rust/t/trapping_rain_water_ii.rs",
    "v": ROOT / "v/t/trapping_rain_water_ii.v",
    "zig": ROOT / "zig/t/trapping_rain_water_ii.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if workload.get("algorithm") != "trapping_rain_water_ii":
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != "trapping_rain_water_ii":
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("unexpected ABI")
    input_meta = workload.get("input", {})
    if input_meta.get("row_count_range") != [1, 8] or input_meta.get("column_count_range") != [1, 8]:
        issues.append("grid dimension bounds mismatch")
    if input_meta.get("height_range") != [0, 1000] or input_meta.get("maximum_valid_length") != 66:
        issues.append("height or frame bounds mismatch")
    if workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call":
        issues.append("unexpected measurement model")

    cases = workload.get("cases", [])
    if not isinstance(cases, list):
        return issues + ["workload cases must be a list"]
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        values = case.get("input_values")
        case_id = case.get("id", "<unnamed>")
        expected = case.get("expected_result")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"fixture input length mismatch: {case_id}")
        if primary_result(values) != expected:
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if independent_result(values) != expected:
            issues.append(f"independent oracle fixture mismatch: {case_id}")

    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "trapping_rain_water_ii" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text in {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")
    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        if ("https://leetcode.com/problems/trapping-rain-water-ii/" not in readme
                or "No statement, examples, tests, submissions, or site code were used." not in readme):
            issues.append("README is missing title-only discovery provenance")
    rights_path = PACKAGE / "RIGHTS.md"
    if rights_path.is_file():
        rights = rights_path.read_text(encoding="utf-8")
        if ("https://leetcode.com/problems/trapping-rain-water-ii/" not in rights
                or "No problem statement" not in rights):
            issues.append("rights note is missing title-only discovery provenance")
    for name in ("trapping_rain_water_ii_oracle.py", "trapping_rain_water_ii_verifier_oracle.py"):
        if not (ROOT / "benchmarks" / name).is_file():
            issues.append(f"missing oracle: {name}")
    elisa = PORTS["elisa"]
    if elisa.is_file():
        source = elisa.read_text(encoding="utf-8")
        if "view[i64]" not in source or "values: i64&" not in source:
            issues.append("Elisa must use safe views internally and refs only at its exported ABI")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
