"""Static inventory and workload fixture review for the polygon-sum package."""

from __future__ import annotations

import json
from pathlib import Path

from minkowski_sum_convex_polygons_oracle import (
    WORKSPACE_BYTES as PRIMARY_WORKSPACE_BYTES,
    expected_output as primary_output,
)
from minkowski_sum_convex_polygons_verifier_oracle import (
    expected_output as independent_output,
    WORKSPACE_BYTES as INDEPENDENT_WORKSPACE_BYTES,
    verify_output,
)

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/p/minkowski_sum_convex_polygons"
LANGUAGE_PATHS = {
    "c": ROOT / "c/p/minkowski_sum_convex_polygons.c",
    "c3": ROOT / "c3/p/minkowski_sum_convex_polygons.c3",
    "cpp": ROOT / "cpp/p/minkowski_sum_convex_polygons.cpp",
    "elisa": ROOT / "elisa/p/minkowski_sum_convex_polygons.elisa",
    "mojo": ROOT / "mojo/p/minkowski_sum_convex_polygons.mojo",
    "nim": ROOT / "nim/p/minkowski_sum_convex_polygons.nim",
    "odin": ROOT / "odin/p/minkowski_sum_convex_polygons.odin",
    "rust": ROOT / "rust/p/minkowski_sum_convex_polygons.rs",
    "v": ROOT / "v/p/minkowski_sum_convex_polygons.v",
    "zig": ROOT / "zig/p/minkowski_sum_convex_polygons.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    if workload.get("algorithm") != "minkowski_sum_convex_polygons":
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != "minkowski_sum_convex_polygons":
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("unexpected ABI")
    input_meta = workload.get("input", {})
    if input_meta.get("polygon_count_range") != [3, 32]:
        issues.append("polygon count bounds mismatch")
    if input_meta.get("coordinate_range") != [-1_000_000, 1_000_000]:
        issues.append("coordinate bounds mismatch")
    if input_meta.get("maximum_valid_input_length") != 130:
        issues.append("maximum input length mismatch")
    if workload.get("output", {}).get("maximum_output_bytes") != 1032:
        issues.append("maximum output capacity mismatch")
    if (workload.get("workspace", {}).get("bytes") != PRIMARY_WORKSPACE_BYTES
            or PRIMARY_WORKSPACE_BYTES != INDEPENDENT_WORKSPACE_BYTES):
        issues.append("workspace byte bound mismatch")
    if workload.get("measurement", {}).get("comparison_model") != "i64_array_bytes_output_call":
        issues.append("unexpected measurement model")

    cases = workload.get("cases", [])
    if not isinstance(cases, list):
        return issues + ["workload cases must be a list"]
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        options = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        values = case.get("input_values")
        case_id = case.get("id", "<unnamed>")
        expected = (case.get("expected_result"), bytes.fromhex(case.get("expected_output_hex", "")))
        primary = primary_output(values, **options)
        independent = independent_output(values, **options)
        if primary != expected:
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if independent != expected:
            issues.append(f"independent oracle fixture mismatch: {case_id}")
        if not verify_output(values, *primary, **options):
            issues.append(f"independent verifier rejected fixture: {case_id}")

    for language, path in LANGUAGE_PATHS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "minkowski_sum_convex_polygons" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text in {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")
    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        if ("https://cp-algorithms.com/geometry/minkowski.html" not in readme
                or "clean-room implementations" not in readme):
            issues.append("README is missing the source link or clean-room provenance")
    rights_path = PACKAGE / "RIGHTS.md"
    if rights_path.is_file():
        rights = rights_path.read_text(encoding="utf-8")
        if ("https://cp-algorithms.com/geometry/minkowski.html" not in rights
                or "CC BY-SA 4.0" not in rights):
            issues.append("rights note is missing the source link or license record")
    for name in (
        "minkowski_sum_convex_polygons_oracle.py",
        "minkowski_sum_convex_polygons_verifier_oracle.py",
    ):
        if not (ROOT / "benchmarks" / name).is_file():
            issues.append(f"missing oracle: {name}")

    elisa = LANGUAGE_PATHS["elisa"].read_text(encoding="utf-8")
    if "view[i64]" not in elisa or "values: i64&" not in elisa:
        issues.append("Elisa must use safe views internally and refs only at its exported ABI")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
