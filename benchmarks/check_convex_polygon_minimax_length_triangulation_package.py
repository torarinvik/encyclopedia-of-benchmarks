"""Static inventory and fixture review for convex-polygon minimax triangulation."""

from __future__ import annotations

import json
from pathlib import Path

from convex_polygon_minimax_length_triangulation_oracle import expected_result as primary_result
from convex_polygon_minimax_length_triangulation_verifier_oracle import expected_result as independent_result

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/c/convex_polygon_minimax_length_triangulation"
PORTS = {
    "c": ROOT / "c/c/convex_polygon_minimax_length_triangulation.c",
    "c3": ROOT / "c3/c/convex_polygon_minimax_length_triangulation.c3",
    "cpp": ROOT / "cpp/c/convex_polygon_minimax_length_triangulation.cpp",
    "elisa": ROOT / "elisa/c/convex_polygon_minimax_length_triangulation.elisa",
    "mojo": ROOT / "mojo/c/convex_polygon_minimax_length_triangulation.mojo",
    "nim": ROOT / "nim/c/convex_polygon_minimax_length_triangulation.nim",
    "odin": ROOT / "odin/c/convex_polygon_minimax_length_triangulation.odin",
    "rust": ROOT / "rust/c/convex_polygon_minimax_length_triangulation.rs",
    "v": ROOT / "v/c/convex_polygon_minimax_length_triangulation.v",
    "zig": ROOT / "zig/c/convex_polygon_minimax_length_triangulation.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    if workload.get("algorithm") != "convex_polygon_minimax_length_triangulation":
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != "convex_polygon_minimax_length_triangulation":
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("unexpected ABI")
    input_contract = workload.get("input", {})
    if input_contract.get("maximum_valid_length") != 25 or input_contract.get("maximum_parseable_length") != 26:
        issues.append("maximum input length mismatch")
    output_contract = workload.get("output", {})
    if output_contract.get("kind") != "signed_64_bit_scalar":
        issues.append("unexpected scalar result type")

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
            continue
        arguments = {
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = case.get("expected_result")
        if primary_result(values, **arguments) != expected:
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if independent_result(values, **arguments) != expected:
            issues.append(f"independent oracle fixture mismatch: {case_id}")

    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "convex_polygon_minimax_length_triangulation" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    if "10.1007/978-1-4939-2864-4_715" not in readme:
        issues.append("README missing source attribution")
    if "does not claim the general-point-set" not in readme:
        issues.append("README must scope the convex-position profile")
    elisa = PORTS["elisa"]
    if elisa.is_file():
        source = elisa.read_text(encoding="utf-8")
        if "input: view[i64]" not in source or "input: i64&" not in source:
            issues.append("Elisa must use safe internal views and an ABI ref wrapper")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
