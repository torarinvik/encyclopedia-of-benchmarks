"""Static inventory for the Fiduccia–Mattheyses package."""

from __future__ import annotations

import json
from pathlib import Path

from fiduccia_mattheyses_hypergraph_bipartitioning_oracle import expected_result as primary_result
from fiduccia_mattheyses_hypergraph_bipartitioning_verifier_oracle import expected_result as independent_result

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/f/fiduccia_mattheyses_hypergraph_bipartitioning"
SYMBOL = "fiduccia_mattheyses_hypergraph_bipartitioning"
PORTS = {
    "c": ROOT / "c/f/fiduccia_mattheyses_hypergraph_bipartitioning.c",
    "c3": ROOT / "c3/f/fiduccia_mattheyses_hypergraph_bipartitioning.c3",
    "cpp": ROOT / "cpp/f/fiduccia_mattheyses_hypergraph_bipartitioning.cpp",
    "elisa": ROOT / "elisa/f/fiduccia_mattheyses_hypergraph_bipartitioning.elisa",
    "mojo": ROOT / "mojo/f/fiduccia_mattheyses_hypergraph_bipartitioning.mojo",
    "nim": ROOT / "nim/f/fiduccia_mattheyses_hypergraph_bipartitioning.nim",
    "odin": ROOT / "odin/f/fiduccia_mattheyses_hypergraph_bipartitioning.odin",
    "rust": ROOT / "rust/f/fiduccia_mattheyses_hypergraph_bipartitioning.rs",
    "v": ROOT / "v/f/fiduccia_mattheyses_hypergraph_bipartitioning.v",
    "zig": ROOT / "zig/f/fiduccia_mattheyses_hypergraph_bipartitioning.zig",
}


def _maximum_case() -> tuple[int, ...]:
    return (8, 12, 15, *(value for _ in range(12) for value in (8, *range(8))))


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL:
        issues.append("unexpected algorithm name or exported symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("unexpected ABI")
    contract = workload.get("input", {})
    if contract.get("maximum_valid_length") != 111 or contract.get("maximum_parseable_length") != 112:
        issues.append("maximum input length mismatch")
    for case in workload.get("cases", []):
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
            issues.append(f"gain-rescoring oracle fixture mismatch: {case_id}")
        if independent_result(values, **arguments) != expected:
            issues.append(f"cut-recount oracle fixture mismatch: {case_id}")

    maximum = _maximum_case()
    if len(maximum) != 111:
        issues.append("maximum input construction mismatch")
    elif primary_result(maximum) != 3087 or independent_result(maximum) != 3087:
        issues.append("maximum repeated-full-net checksum mismatch")
    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    if "10.1109/DAC.1982.1585498" not in readme:
        issues.append("README missing source attribution")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
