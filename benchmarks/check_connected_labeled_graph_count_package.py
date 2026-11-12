"""Static inventory and fixture review for connected labeled graph ports."""

from __future__ import annotations

import json
from pathlib import Path

from connected_labeled_graph_count_oracle import (
    MAX_N,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    expected_result as primary_result,
)
from connected_labeled_graph_count_verifier_oracle import (
    MAX_N as INDEPENDENT_MAX_N,
    MAX_PARSEABLE_INPUT_LENGTH as INDEPENDENT_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH as INDEPENDENT_MAX_VALID_INPUT_LENGTH,
    expected_result as independent_result,
)

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/c/connected_labeled_graph_count"
PORTS = {
    "c": ROOT / "c/c/connected_labeled_graph_count.c",
    "c3": ROOT / "c3/c/connected_labeled_graph_count.c3",
    "cpp": ROOT / "cpp/c/connected_labeled_graph_count.cpp",
    "elisa": ROOT / "elisa/c/connected_labeled_graph_count.elisa",
    "mojo": ROOT / "mojo/c/connected_labeled_graph_count.mojo",
    "nim": ROOT / "nim/c/connected_labeled_graph_count.nim",
    "odin": ROOT / "odin/c/connected_labeled_graph_count.odin",
    "rust": ROOT / "rust/c/connected_labeled_graph_count.rs",
    "v": ROOT / "v/c/connected_labeled_graph_count.v",
    "zig": ROOT / "zig/c/connected_labeled_graph_count.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    if workload.get("algorithm") != "connected_labeled_graph_count":
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != "connected_labeled_graph_count":
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("unexpected ABI")
    if workload.get("input", {}).get("vertex_count_range") != [1, MAX_N]:
        issues.append("vertex-count bounds mismatch")
    if INDEPENDENT_MAX_N != MAX_N:
        issues.append("primary and independent vertex-count bounds differ")
    if workload.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH:
        issues.append("maximum valid input length mismatch")
    if workload.get("input", {}).get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH:
        issues.append("maximum parseable input length mismatch")
    if (INDEPENDENT_MAX_VALID_INPUT_LENGTH, INDEPENDENT_MAX_PARSEABLE_INPUT_LENGTH) != (
        MAX_VALID_INPUT_LENGTH,
        MAX_PARSEABLE_INPUT_LENGTH,
    ):
        issues.append("primary and independent input-length bounds differ")
    if workload.get("output", {}).get("modulus") != 998244353:
        issues.append("output modulus mismatch")

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
        expected = case.get("expected_result")
        if primary_result(values) != expected:
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if independent_result(values) != expected:
            issues.append(f"independent oracle fixture mismatch: {case_id}")

    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "connected_labeled_graph_count" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")

    readme_path = PACKAGE / "README.md"
    if readme_path.is_file() and "https://cp-algorithms.com/combinatorics/counting_labeled_graphs.html" not in readme_path.read_text(encoding="utf-8"):
        issues.append("README missing the algorithm source")
    elisa = PORTS["elisa"]
    if elisa.is_file():
        source = elisa.read_text(encoding="utf-8")
        if "view[i64]" not in source or "input: i64&" not in source:
            issues.append("Elisa must use safe views internally and refs only at its exported ABI")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
