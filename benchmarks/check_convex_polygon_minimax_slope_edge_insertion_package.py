"""Static package inventory and fixture review; intentionally not auto-run on import."""

from __future__ import annotations

import json
import re
from pathlib import Path

from convex_polygon_minimax_slope_edge_insertion_oracle import expected_result as primary_result
from convex_polygon_minimax_slope_edge_insertion_verifier_oracle import expected_result as independent_result

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/c/convex_polygon_minimax_slope_edge_insertion"
PORTS = {
    "c": ROOT / "c/c/convex_polygon_minimax_slope_edge_insertion.c",
    "c3": ROOT / "c3/c/convex_polygon_minimax_slope_edge_insertion.c3",
    "cpp": ROOT / "cpp/c/convex_polygon_minimax_slope_edge_insertion.cpp",
    "elisa": ROOT / "elisa/c/convex_polygon_minimax_slope_edge_insertion.elisa",
    "mojo": ROOT / "mojo/c/convex_polygon_minimax_slope_edge_insertion.mojo",
    "nim": ROOT / "nim/c/convex_polygon_minimax_slope_edge_insertion.nim",
    "odin": ROOT / "odin/c/convex_polygon_minimax_slope_edge_insertion.odin",
    "rust": ROOT / "rust/c/convex_polygon_minimax_slope_edge_insertion.rs",
    "v": ROOT / "v/c/convex_polygon_minimax_slope_edge_insertion.v",
    "zig": ROOT / "zig/c/convex_polygon_minimax_slope_edge_insertion.zig",
}
SYMBOL = "convex_polygon_minimax_slope_edge_insertion"


def static_issues(workload: dict | None = None) -> list[str]:
    issues: list[str] = []
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload metadata: {error}"]

    if workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL:
        issues.append("algorithm or export symbol mismatch")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("unexpected ABI")
    input_contract = workload.get("input", {})
    if (input_contract.get("maximum_valid_length") != 13
            or input_contract.get("maximum_parseable_length") != 14
            or input_contract.get("exact_length") != "1 + 3*N"):
        issues.append("input framing mismatch")
    if workload.get("output", {}).get("maximum_result") != 4:
        issues.append("output bound mismatch")

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
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")

    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        for required in (
            "10.1007/978-1-4939-2864-4_715",
            "10.1007/BF02573962",
            "does not claim to reproduce the paper's general-point-set algorithm",
        ):
            if required not in readme:
                issues.append(f"README missing required provenance/scope text: {required}")
        for relative in (
            "../../../c/c/convex_polygon_minimax_slope_edge_insertion.c",
            "../../../c3/c/convex_polygon_minimax_slope_edge_insertion.c3",
            "../../../cpp/c/convex_polygon_minimax_slope_edge_insertion.cpp",
            "../../../elisa/c/convex_polygon_minimax_slope_edge_insertion.elisa",
            "../../../mojo/c/convex_polygon_minimax_slope_edge_insertion.mojo",
            "../../../nim/c/convex_polygon_minimax_slope_edge_insertion.nim",
            "../../../odin/c/convex_polygon_minimax_slope_edge_insertion.odin",
            "../../../rust/c/convex_polygon_minimax_slope_edge_insertion.rs",
            "../../../v/c/convex_polygon_minimax_slope_edge_insertion.v",
            "../../../zig/c/convex_polygon_minimax_slope_edge_insertion.zig",
        ):
            if f"]({relative})" not in readme:
                issues.append(f"README missing language link target: {relative}")
        for target in re.findall(r"\]\(([^)]+)\)", readme):
            if target.startswith(("http://", "https://")):
                continue
            resolved = (readme_path.parent / target).resolve()
            if not resolved.is_file():
                issues.append(f"README link target does not exist: {target}")

    if not (ROOT / "benchmarks/convex_polygon_minimax_slope_edge_insertion_oracle.py").is_file():
        issues.append("missing primary oracle")
    if not (ROOT / "benchmarks/convex_polygon_minimax_slope_edge_insertion_verifier_oracle.py").is_file():
        issues.append("missing independent oracle")
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
