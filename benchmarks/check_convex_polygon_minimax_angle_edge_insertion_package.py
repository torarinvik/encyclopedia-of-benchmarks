"""Static package inventory and fixture review for the min-max-angle profile."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from convex_polygon_minimax_angle_edge_insertion_oracle import expected_result as primary_result
from convex_polygon_minimax_angle_edge_insertion_verifier_oracle import expected_result as independent_result

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/c/convex_polygon_minimax_angle_edge_insertion"
PORTS = {
    "c": ROOT / "c/c/convex_polygon_minimax_angle_edge_insertion.c",
    "c3": ROOT / "c3/c/convex_polygon_minimax_angle_edge_insertion.c3",
    "cpp": ROOT / "cpp/c/convex_polygon_minimax_angle_edge_insertion.cpp",
    "elisa": ROOT / "elisa/c/convex_polygon_minimax_angle_edge_insertion.elisa",
    "mojo": ROOT / "mojo/c/convex_polygon_minimax_angle_edge_insertion.mojo",
    "nim": ROOT / "nim/c/convex_polygon_minimax_angle_edge_insertion.nim",
    "odin": ROOT / "odin/c/convex_polygon_minimax_angle_edge_insertion.odin",
    "rust": ROOT / "rust/c/convex_polygon_minimax_angle_edge_insertion.rs",
    "v": ROOT / "v/c/convex_polygon_minimax_angle_edge_insertion.v",
    "zig": ROOT / "zig/c/convex_polygon_minimax_angle_edge_insertion.zig",
}
SYMBOL = "convex_polygon_minimax_angle_edge_insertion"


def static_issues(workload: dict[str, Any] | None = None) -> list[str]:
    """Return metadata, fixture, source-link, and inventory issues without subprocesses."""
    issues: list[str] = []
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload metadata: {error}"]

    if workload.get("algorithm") != SYMBOL:
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != SYMBOL:
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("unexpected ABI")
    input_contract = workload.get("input", {})
    if input_contract.get("maximum_valid_length") != 9 or input_contract.get("maximum_parseable_length") != 10:
        issues.append("input-frame bounds mismatch")
    if input_contract.get("vertex_count_range") != [3, 4]:
        issues.append("unexpected vertex-count profile")
    output_contract = workload.get("output", {})
    if output_contract.get("kind") != "signed_64_bit_scalar" or output_contract.get("maximum_result") != 12:
        issues.append("output contract mismatch")

    cases = workload.get("cases", [])
    if not isinstance(cases, list):
        return issues + ["workload cases must be a list"]
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        case_id = case.get("id", "<unnamed>")
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"fixture input length mismatch: {case_id}")
            continue
        arguments = {
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = case.get("expected_result")
        if primary_result(values, **arguments) != expected:
            issues.append(f"primary reference fixture mismatch: {case_id}")
        if independent_result(values, **arguments) != expected:
            issues.append(f"independent reference fixture mismatch: {case_id}")

    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")

    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")

    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    except OSError:
        return issues
    for required in (
        "10.1007/978-1-4939-2864-4_715",
        "10.1137/0913058",
        "does not claim to reproduce the paper's general-point-set",
        "strictly smaller",
        "Delaunay",
    ):
        if required not in readme:
            issues.append(f"README missing required provenance or scope text: {required}")
    for target in re.findall(r"\]\(([^)]+)\)", readme):
        if target.startswith(("https://", "http://", "#")):
            continue
        resolved = (PACKAGE / target).resolve()
        if not resolved.is_relative_to(ROOT.resolve()) or not resolved.is_file():
            issues.append(f"README local target does not resolve: {target}")
    for relative in (
        "../../../c/c/convex_polygon_minimax_angle_edge_insertion.c",
        "../../../c3/c/convex_polygon_minimax_angle_edge_insertion.c3",
        "../../../cpp/c/convex_polygon_minimax_angle_edge_insertion.cpp",
        "../../../elisa/c/convex_polygon_minimax_angle_edge_insertion.elisa",
        "../../../mojo/c/convex_polygon_minimax_angle_edge_insertion.mojo",
        "../../../nim/c/convex_polygon_minimax_angle_edge_insertion.nim",
        "../../../odin/c/convex_polygon_minimax_angle_edge_insertion.odin",
        "../../../rust/c/convex_polygon_minimax_angle_edge_insertion.rs",
        "../../../v/c/convex_polygon_minimax_angle_edge_insertion.v",
        "../../../zig/c/convex_polygon_minimax_angle_edge_insertion.zig",
    ):
        if f"]({relative})" not in readme:
            issues.append(f"README missing exact port target: {relative}")

    elisa_path = PORTS["elisa"]
    if elisa_path.is_file():
        elisa = elisa_path.read_text(encoding="utf-8")
        if "input: view[i64]" not in elisa or "input: i64&" not in elisa:
            issues.append("Elisa must use an internal view and keep the ABI reference at the export")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
