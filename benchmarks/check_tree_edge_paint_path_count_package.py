"""Static inventory and fixture review for tree edge painting path counts."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .tree_edge_paint_path_count_oracle import (
        MAX_N,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_QUERIES as MAX_Q,
        MAX_VALID_INPUT_LENGTH,
        expected_result as primary_result,
    )
    from .tree_edge_paint_path_count_independent_oracle import (
        expected_result as independent_result,
    )
except ImportError:  # Direct execution from the benchmarks directory.
    from tree_edge_paint_path_count_oracle import (
        MAX_N,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_QUERIES as MAX_Q,
        MAX_VALID_INPUT_LENGTH,
        expected_result as primary_result,
    )
    from tree_edge_paint_path_count_independent_oracle import (
        expected_result as independent_result,
    )

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/t/tree_edge_paint_path_count"
SOURCE_URL = "https://cp-algorithms.com/graph/tree_painting.html"
PORTS = {
    "c": ROOT / "c/t/tree_edge_paint_path_count.c",
    "c3": ROOT / "c3/t/tree_edge_paint_path_count.c3",
    "cpp": ROOT / "cpp/t/tree_edge_paint_path_count.cpp",
    "elisa": ROOT / "elisa/t/tree_edge_paint_path_count.elisa",
    "mojo": ROOT / "mojo/t/tree_edge_paint_path_count.mojo",
    "nim": ROOT / "nim/t/tree_edge_paint_path_count.nim",
    "odin": ROOT / "odin/t/tree_edge_paint_path_count.odin",
    "rust": ROOT / "rust/t/tree_edge_paint_path_count.rs",
    "v": ROOT / "v/t/tree_edge_paint_path_count.v",
    "zig": ROOT / "zig/t/tree_edge_paint_path_count.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    if workload.get("algorithm") != "tree_edge_paint_path_count":
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != "tree_edge_paint_path_count":
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("unexpected ABI")
    if workload.get("source", {}).get("url") != SOURCE_URL:
        issues.append("source URL mismatch")
    contract = workload.get("input", {})
    if contract.get("n_range") != [1, MAX_N] or contract.get("query_count_range") != [0, MAX_Q]:
        issues.append("tree or operation bounds mismatch")
    if contract.get("exact_length") != "2+2*(N-1)+3*Q":
        issues.append("input-length formula mismatch")
    if contract.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH:
        issues.append("maximum valid input length mismatch")
    if contract.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH:
        issues.append("maximum parseable input length mismatch")
    max_paints = MAX_N - 1
    max_checksum = max((MAX_Q - paints) * paints for paints in range(max_paints + 1))
    if workload.get("output", {}).get("valid_range") != [0, max_checksum]:
        issues.append("checksum range mismatch")

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
        if len(values) > MAX_PARSEABLE_INPUT_LENGTH:
            issues.append(f"fixture exceeds parseable input bound: {case_id}")
        expected = case.get("expected_result")
        if primary_result(values) != expected:
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if independent_result(values) != expected:
            issues.append(f"independent oracle fixture mismatch: {case_id}")

    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "tree_edge_paint_path_count" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")
    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        if SOURCE_URL not in readme:
            issues.append("README missing source URL")
        if "directional" not in readme.lower():
            issues.append("README missing directional-tour algorithm description")
    elisa = PORTS["elisa"]
    if elisa.is_file():
        source = elisa.read_text(encoding="utf-8")
        if "view[i64]" not in source or "input: i64&" not in source:
            issues.append("Elisa must use safe views internally and refs only at the exported ABI")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
