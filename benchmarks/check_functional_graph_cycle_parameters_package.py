"""Static inventory and fixture review for functional graph cycle parameters."""

from __future__ import annotations

import json
from pathlib import Path

from functional_graph_cycle_parameters_oracle import (
    ENCODING_BASE,
    MAX_N,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    expected_result as primary_result,
)
from functional_graph_cycle_parameters_verifier_oracle import (
    ENCODING_BASE as INDEPENDENT_ENCODING_BASE,
    MAX_N as INDEPENDENT_MAX_N,
    MAX_PARSEABLE_INPUT_LENGTH as INDEPENDENT_MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH as INDEPENDENT_MAX_VALID_INPUT_LENGTH,
    expected_result as independent_result,
)

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/f/functional_graph_cycle_parameters"
SOURCE_URL = "https://cp-algorithms.com/others/tortoise_and_hare.html"
PORTS = {
    "c": ROOT / "c/f/functional_graph_cycle_parameters.c",
    "c3": ROOT / "c3/f/functional_graph_cycle_parameters.c3",
    "cpp": ROOT / "cpp/f/functional_graph_cycle_parameters.cpp",
    "elisa": ROOT / "elisa/f/functional_graph_cycle_parameters.elisa",
    "mojo": ROOT / "mojo/f/functional_graph_cycle_parameters.mojo",
    "nim": ROOT / "nim/f/functional_graph_cycle_parameters.nim",
    "odin": ROOT / "odin/f/functional_graph_cycle_parameters.odin",
    "rust": ROOT / "rust/f/functional_graph_cycle_parameters.rs",
    "v": ROOT / "v/f/functional_graph_cycle_parameters.v",
    "zig": ROOT / "zig/f/functional_graph_cycle_parameters.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    if workload.get("algorithm") != "functional_graph_cycle_parameters":
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != "functional_graph_cycle_parameters":
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("unexpected ABI")
    if workload.get("source", {}).get("url") != SOURCE_URL:
        issues.append("source URL mismatch")

    input_contract = workload.get("input", {})
    if input_contract.get("n_range") != [1, MAX_N]:
        issues.append("N bound mismatch")
    if input_contract.get("exact_length") != "N+2":
        issues.append("exact input-length formula mismatch")
    if input_contract.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH:
        issues.append("maximum valid input bound mismatch")
    if input_contract.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH:
        issues.append("maximum parseable input bound mismatch")
    if (INDEPENDENT_MAX_N, INDEPENDENT_MAX_VALID_INPUT_LENGTH,
            INDEPENDENT_MAX_PARSEABLE_INPUT_LENGTH, INDEPENDENT_ENCODING_BASE) != (
            MAX_N, MAX_VALID_INPUT_LENGTH, MAX_PARSEABLE_INPUT_LENGTH, ENCODING_BASE):
        issues.append("primary and independent oracle contracts differ")
    if workload.get("output", {}).get("encoding") != "65*mu+lambda":
        issues.append("output encoding mismatch")
    if workload.get("output", {}).get("valid_range") != [1, ENCODING_BASE * (MAX_N - 1) + 1]:
        issues.append("valid output range mismatch")
    if ENCODING_BASE != MAX_N + 1:
        issues.append("encoding base does not cover every valid lambda")

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
        if len(values) > MAX_PARSEABLE_INPUT_LENGTH:
            issues.append(f"fixture exceeds parseable bound: {case_id}")

    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "functional_graph_cycle_parameters" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")

    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        if SOURCE_URL not in readme:
            issues.append("README missing algorithm provenance")
        if "65*mu+lambda" not in readme:
            issues.append("README missing scalar output encoding")
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
