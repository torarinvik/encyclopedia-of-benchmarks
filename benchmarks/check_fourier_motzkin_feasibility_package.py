"""Static package inventory for Fourier–Motzkin feasibility."""

from __future__ import annotations

import json
from pathlib import Path

from fourier_motzkin_feasibility_oracle import expected_result as primary_result
from fourier_motzkin_feasibility_verifier_oracle import expected_result as independent_result

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/f/fourier_motzkin_feasibility"
SYMBOL = "fourier_motzkin_feasibility"
PORTS = {
    "c": ROOT / "c/f/fourier_motzkin_feasibility.c",
    "c3": ROOT / "c3/f/fourier_motzkin_feasibility.c3",
    "cpp": ROOT / "cpp/f/fourier_motzkin_feasibility.cpp",
    "elisa": ROOT / "elisa/f/fourier_motzkin_feasibility.elisa",
    "mojo": ROOT / "mojo/f/fourier_motzkin_feasibility.mojo",
    "nim": ROOT / "nim/f/fourier_motzkin_feasibility.nim",
    "odin": ROOT / "odin/f/fourier_motzkin_feasibility.odin",
    "rust": ROOT / "rust/f/fourier_motzkin_feasibility.rs",
    "v": ROOT / "v/fourier_motzkin_feasibility.v",
    "zig": ROOT / "zig/f/fourier_motzkin_feasibility.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL:
        issues.append("unexpected algorithm or exported symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("unexpected ABI")
    input_contract = workload.get("input", {})
    if (input_contract.get("maximum_valid_length") != 26
            or input_contract.get("maximum_parseable_length") != 27):
        issues.append("maximum input length mismatch")
    for case in workload.get("cases", []):
        values = case.get("input_values")
        case_id = case.get("id", "<unnamed>")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"fixture framing mismatch: {case_id}")
            continue
        arguments = {"input_is_null": case.get("input_is_null", False),
                     "input_length": case.get("input_length")}
        expected = case.get("expected_result")
        if primary_result(values, **arguments) != expected:
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if independent_result(values, **arguments) != expected:
            issues.append(f"vertex oracle fixture mismatch: {case_id}")
    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    if "oi-wiki.org/math/fourier-motzkin-elimination/" not in readme:
        issues.append("README missing OI Wiki attribution")
    elisa = PORTS["elisa"]
    if elisa.is_file():
        source = elisa.read_text(encoding="utf-8")
        if "view[i64]" not in source or "i64&" not in source:
            issues.append("Elisa should use an internal view and reference ABI wrapper")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
