"""Static inventory and fixture review for the ray-casting package."""

from __future__ import annotations

import json
from pathlib import Path

from point_in_polygon_ray_casting_oracle import expected_result as primary_result
from point_in_polygon_ray_casting_verifier_oracle import (
    expected_result as independent_result,
    verify_result,
)

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/p/point_in_polygon_ray_casting"
LANGUAGE_PATHS = {
    "c": ROOT / "c/p/point_in_polygon_ray_casting.c",
    "c3": ROOT / "c3/p/point_in_polygon_ray_casting.c3",
    "cpp": ROOT / "cpp/p/point_in_polygon_ray_casting.cpp",
    "elisa": ROOT / "elisa/p/point_in_polygon_ray_casting.elisa",
    "mojo": ROOT / "mojo/p/point_in_polygon_ray_casting.mojo",
    "nim": ROOT / "nim/p/point_in_polygon_ray_casting.nim",
    "odin": ROOT / "odin/p/point_in_polygon_ray_casting.odin",
    "rust": ROOT / "rust/p/point_in_polygon_ray_casting.rs",
    "v": ROOT / "v/p/point_in_polygon_ray_casting.v",
    "zig": ROOT / "zig/p/point_in_polygon_ray_casting.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    if workload.get("algorithm") != "point_in_polygon_ray_casting":
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != "point_in_polygon_ray_casting":
        issues.append("unexpected function symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("unexpected ABI")
    input_meta = workload.get("input", {})
    if input_meta.get("vertex_count_range") != [3, 64]:
        issues.append("vertex-count bounds mismatch")
    if input_meta.get("coordinate_range") != [-1_000_000, 1_000_000]:
        issues.append("coordinate bounds mismatch")
    if input_meta.get("maximum_input_length") != 131:
        issues.append("maximum input length mismatch")
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
        input_length = case.get("input_length")
        input_is_null = case.get("input_is_null", False)
        case_id = case.get("id", "<unnamed>")
        primary = primary_result(values, input_length, input_is_null)
        independent = independent_result(values, input_length, input_is_null)
        if primary != case.get("expected_result"):
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if independent != case.get("expected_result"):
            issues.append(f"independent oracle fixture mismatch: {case_id}")
        if not verify_result(values, primary, input_length, input_is_null):
            issues.append(f"independent verifier rejected fixture: {case_id}")

    for language, path in LANGUAGE_PATHS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "point_in_polygon_ray_casting" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text in {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")
    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        if ("https://rosettagit.org/tasks/ray-casting-algorithm/" not in readme
                or "clean-room implementations" not in readme):
            issues.append("README is missing the source link or clean-room provenance")
    rights_path = PACKAGE / "RIGHTS.md"
    if rights_path.is_file():
        rights = rights_path.read_text(encoding="utf-8")
        if ("https://rosettagit.org/tasks/ray-casting-algorithm/" not in rights
                or "GFDL" not in rights):
            issues.append("rights note is missing the source link or license record")
    for name in (
        "point_in_polygon_ray_casting_oracle.py",
        "point_in_polygon_ray_casting_verifier_oracle.py",
    ):
        if not (ROOT / "benchmarks" / name).is_file():
            issues.append(f"missing oracle: {name}")

    elisa = LANGUAGE_PATHS["elisa"].read_text(encoding="utf-8")
    if "view[i64]" not in elisa or "values: i64&" not in elisa:
        issues.append("Elisa must use a safe view internally and an ABI reference in its wrapper")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
