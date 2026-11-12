"""Static inventory and fixture review for Bostan–Mori recurrence ports."""

from __future__ import annotations

import json
from pathlib import Path

from bostan_mori_recurrence_term_oracle import (
    MAX_INDEX,
    MAX_ORDER,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    MODULUS,
    expected_result as primary_result,
)
from bostan_mori_recurrence_term_verifier_oracle import (
    MAX_INDEX as INDEPENDENT_MAX_INDEX,
    MAX_ORDER as INDEPENDENT_MAX_ORDER,
    MAX_PARSEABLE_INPUT_LENGTH as INDEPENDENT_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH as INDEPENDENT_MAX_VALID_INPUT_LENGTH,
    MODULUS as INDEPENDENT_MODULUS,
    expected_result as independent_result,
)

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/b/bostan_mori_recurrence_term"
PORTS = {
    "c": ROOT / "c/b/bostan_mori_recurrence_term.c",
    "c3": ROOT / "c3/b/bostan_mori_recurrence_term.c3",
    "cpp": ROOT / "cpp/b/bostan_mori_recurrence_term.cpp",
    "elisa": ROOT / "elisa/b/bostan_mori_recurrence_term.elisa",
    "mojo": ROOT / "mojo/b/bostan_mori_recurrence_term.mojo",
    "nim": ROOT / "nim/b/bostan_mori_recurrence_term.nim",
    "odin": ROOT / "odin/b/bostan_mori_recurrence_term.odin",
    "rust": ROOT / "rust/b/bostan_mori_recurrence_term.rs",
    "v": ROOT / "v/b/bostan_mori_recurrence_term.v",
    "zig": ROOT / "zig/b/bostan_mori_recurrence_term.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    if workload.get("algorithm") != "bostan_mori_recurrence_term":
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != "bostan_mori_recurrence_term":
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("unexpected ABI")
    input_contract = workload.get("input", {})
    if input_contract.get("order_range") != [1, MAX_ORDER]:
        issues.append("recurrence-order bounds mismatch")
    if input_contract.get("index_range") != [0, MAX_INDEX]:
        issues.append("target-index bounds mismatch")
    if input_contract.get("exact_length") != "2+2*d":
        issues.append("input framing contract mismatch")
    if input_contract.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH:
        issues.append("maximum valid input length mismatch")
    if input_contract.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH:
        issues.append("maximum parseable input length mismatch")
    if (INDEPENDENT_MAX_ORDER, INDEPENDENT_MAX_INDEX, INDEPENDENT_MODULUS,
            INDEPENDENT_MAX_VALID_INPUT_LENGTH, INDEPENDENT_MAX_PARSEABLE_INPUT_LENGTH) != (
            MAX_ORDER, MAX_INDEX, MODULUS, MAX_VALID_INPUT_LENGTH, MAX_PARSEABLE_INPUT_LENGTH):
        issues.append("primary and independent oracle bounds differ")
    if workload.get("output", {}).get("modulus") != MODULUS:
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
            issues.append(f"Bostan–Mori fixture mismatch: {case_id}")
        if independent_result(values) != expected:
            issues.append(f"companion-matrix fixture mismatch: {case_id}")

    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "bostan_mori_recurrence_term" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")

    readme_path = PACKAGE / "README.md"
    if readme_path.is_file() and "https://arxiv.org/abs/2008.08822" not in readme_path.read_text(encoding="utf-8"):
        issues.append("README missing the algorithm source")
    elisa = PORTS["elisa"]
    if elisa.is_file():
        source = elisa.read_text(encoding="utf-8")
        if "values: view[i64]" not in source or "input: i64&" not in source:
            issues.append("Elisa must use safe views internally and a reference only at the exported ABI")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
