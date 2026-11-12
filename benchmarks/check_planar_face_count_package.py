"""Static inventory and fixture review for planar face counting ports."""

from __future__ import annotations

import json
from pathlib import Path

from planar_face_count_oracle import expected_result as primary_result
from planar_face_count_verifier_oracle import expected_result as independent_result

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/p/planar_face_count"
PORTS = {
    "c": ROOT / "c/p/planar_face_count.c",
    "c3": ROOT / "c3/p/planar_face_count.c3",
    "cpp": ROOT / "cpp/p/planar_face_count.cpp",
    "elisa": ROOT / "elisa/p/planar_face_count.elisa",
    "mojo": ROOT / "mojo/p/planar_face_count.mojo",
    "nim": ROOT / "nim/p/planar_face_count.nim",
    "odin": ROOT / "odin/p/planar_face_count.odin",
    "rust": ROOT / "rust/p/planar_face_count.rs",
    "v": ROOT / "v/p/planar_face_count.v",
    "zig": ROOT / "zig/p/planar_face_count.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if workload.get("algorithm") != "planar_face_count":
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != "planar_face_count":
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("unexpected ABI")
    if workload.get("input", {}).get("maximum_valid_length") != 118:
        issues.append("maximum input length mismatch")
    if workload.get("output", {}).get("maximum_result") != 28:
        issues.append("maximum face count mismatch")
    cases = workload.get("cases", [])
    if not isinstance(cases, list):
        return issues + ["workload cases must be a list"]
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        values = case.get("input_values")
        case_id = case.get("id", "<unnamed>")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"fixture input length mismatch: {case_id}")
        expected = case.get("expected_result")
        if primary_result(values) != expected:
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if independent_result(values) != expected:
            issues.append(f"independent oracle fixture mismatch: {case_id}")
    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "planar_face_count" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    if "https://cp-algorithms.com/geometry/planar.html" not in readme:
        issues.append("README missing source attribution")
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
