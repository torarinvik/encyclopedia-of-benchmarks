"""Static inventory for the Dinkelbach fixed-cardinality ratio package."""

from __future__ import annotations

import json
from pathlib import Path

from dinkelbach_fixed_cardinality_ratio_oracle import expected_result as primary_result
from dinkelbach_fixed_cardinality_ratio_verifier_oracle import expected_result as independent_result

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/d/dinkelbach_fixed_cardinality_ratio"
SYMBOL = "dinkelbach_fixed_cardinality_ratio"
PORTS = {
    "c": ROOT / "c/d/dinkelbach_fixed_cardinality_ratio.c",
    "c3": ROOT / "c3/d/dinkelbach_fixed_cardinality_ratio.c3",
    "cpp": ROOT / "cpp/d/dinkelbach_fixed_cardinality_ratio.cpp",
    "elisa": ROOT / "elisa/d/dinkelbach_fixed_cardinality_ratio.elisa",
    "mojo": ROOT / "mojo/d/dinkelbach_fixed_cardinality_ratio.mojo",
    "nim": ROOT / "nim/d/dinkelbach_fixed_cardinality_ratio.nim",
    "odin": ROOT / "odin/d/dinkelbach_fixed_cardinality_ratio.odin",
    "rust": ROOT / "rust/d/dinkelbach_fixed_cardinality_ratio.rs",
    "v": ROOT / "v/dinkelbach_fixed_cardinality_ratio.v",
    "zig": ROOT / "zig/d/dinkelbach_fixed_cardinality_ratio.zig",
}


def _maximum_equal_ratio_case() -> tuple[int, ...]:
    return (12, 6, *(value for _ in range(12) for value in (10_000, 1)))


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
    if (contract.get("maximum_valid_length") != 26
            or contract.get("maximum_parseable_length") != 27):
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
            issues.append(f"Dinkelbach oracle fixture mismatch: {case_id}")
        if independent_result(values, **arguments) != expected:
            issues.append(f"exhaustive oracle fixture mismatch: {case_id}")

    maximum = _maximum_equal_ratio_case()
    if len(maximum) != 26:
        issues.append("maximum input construction mismatch")
    elif primary_result(maximum) != 1_200_010_001 or independent_result(maximum) != 1_200_010_001:
        issues.append("maximum equal-ratio checksum mismatch")
    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    if "10.1287/mnsc.13.7.492" not in readme or "frac-programming" not in readme:
        issues.append("README missing source attribution")
    elisa = PORTS["elisa"]
    if elisa.is_file():
        source = elisa.read_text(encoding="utf-8")
        if "view[i64]" not in source or "i64&" not in source:
            issues.append("Elisa should use a safe internal view and reference ABI wrapper")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
