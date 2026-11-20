"""Static inventory and fixture review for the fixed-point HITS package."""

from __future__ import annotations

import json
from pathlib import Path

from hits_fixed_point_oracle import expected_result as primary_result
from hits_fixed_point_verifier_oracle import expected_result as independent_result

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/h/hits_fixed_point"
PORTS = {
    "c": ROOT / "c/h/hits_fixed_point.c",
    "c3": ROOT / "c3/h/hits_fixed_point.c3",
    "cpp": ROOT / "cpp/h/hits_fixed_point.cpp",
    "elisa": ROOT / "elisa/h/hits_fixed_point.elisa",
    "mojo": ROOT / "mojo/h/hits_fixed_point.mojo",
    "nim": ROOT / "nim/h/hits_fixed_point.nim",
    "odin": ROOT / "odin/h/hits_fixed_point.odin",
    "rust": ROOT / "rust/h/hits_fixed_point.rs",
    "v": ROOT / "v/h/hits_fixed_point.v",
    "zig": ROOT / "zig/h/hits_fixed_point.zig",
}


def _maximum_regular_case() -> tuple[int, ...]:
    edges = tuple((vertex, (vertex + offset) % 16)
                  for vertex in range(16) for offset in range(1, 5))
    return (16, len(edges), 32, *(endpoint for edge in edges for endpoint in edge))


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if workload.get("algorithm") != "hits_fixed_point":
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != "hits_fixed_point":
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("unexpected ABI")
    input_contract = workload.get("input", {})
    if (input_contract.get("maximum_valid_length") != 131
            or input_contract.get("maximum_parseable_length") != 132):
        issues.append("maximum input length mismatch")
    if workload.get("output", {}).get("score_scale") != 1_000_000:
        issues.append("fixed-point score scale mismatch")

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
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if independent_result(values, **arguments) != expected:
            issues.append(f"independent oracle fixture mismatch: {case_id}")

    maximum_values = _maximum_regular_case()
    if len(maximum_values) != 131:
        issues.append("maximum input construction mismatch")
    elif (primary_result(maximum_values) != 557_073_000_000
          or independent_result(maximum_values) != 557_073_000_000):
        issues.append("maximum regular graph checksum mismatch")
    if (primary_result((*maximum_values, 0)) != -1
            or independent_result((*maximum_values, 0)) != -1):
        issues.append("maximum parseable trailing frame was accepted")

    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "hits_fixed_point" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    if "10.1145/324133.324140" not in readme:
        issues.append("README missing source attribution")
    elisa = PORTS["elisa"]
    if elisa.is_file():
        source = elisa.read_text(encoding="utf-8")
        if "view[i64]" not in source or "i64&" not in source:
            issues.append("Elisa must use a safe internal view and reference ABI wrapper")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
