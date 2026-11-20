"""Static inventory for the 2D Mo rectangle workload."""

from __future__ import annotations

import json
from pathlib import Path

from mo_2d_rectangle_frequency_square_oracle import expected_result as primary_result
from mo_2d_rectangle_frequency_square_verifier_oracle import expected_result as independent_result

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/m/mo_2d_rectangle_frequency_square"
PORTS = {
    "c": ROOT / "c/m/mo_2d_rectangle_frequency_square.c",
    "c3": ROOT / "c3/m/mo_2d_rectangle_frequency_square.c3",
    "cpp": ROOT / "cpp/m/mo_2d_rectangle_frequency_square.cpp",
    "elisa": ROOT / "elisa/m/mo_2d_rectangle_frequency_square.elisa",
    "mojo": ROOT / "mojo/m/mo_2d_rectangle_frequency_square.mojo",
    "nim": ROOT / "nim/m/mo_2d_rectangle_frequency_square.nim",
    "odin": ROOT / "odin/m/mo_2d_rectangle_frequency_square.odin",
    "rust": ROOT / "rust/m/mo_2d_rectangle_frequency_square.rs",
    "v": ROOT / "v/m/mo_2d_rectangle_frequency_square.v",
    "zig": ROOT / "zig/m/mo_2d_rectangle_frequency_square.zig",
}
SYMBOL = "mo_2d_rectangle_frequency_square"


def _maximum_input() -> tuple[int, ...]:
    return (8, 32, *([0] * 64), *([0, 0, 7, 7] * 32))


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
    if (contract.get("maximum_valid_length") != 194
            or contract.get("maximum_parseable_length") != 195):
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
            issues.append(f"movement oracle fixture mismatch: {case_id}")
        if independent_result(values, **arguments) != expected:
            issues.append(f"direct-scan fixture mismatch: {case_id}")

    maximum = _maximum_input()
    if len(maximum) != 194:
        issues.append("maximum input construction mismatch")
    elif primary_result(maximum) != 2_162_688 or independent_result(maximum) != 2_162_688:
        issues.append("maximum all-equal matrix checksum mismatch")
    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    if "mo-2dimen" not in readme or "two-dimensional Mo" not in readme:
        issues.append("README missing source attribution or algorithm distinction")
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
