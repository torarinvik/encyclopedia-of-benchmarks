"""Static inventory and fixture review for balanced-ternary conversion ports."""

from __future__ import annotations

import json
from pathlib import Path

from balanced_ternary_conversion_oracle import expected_output as primary_output
from balanced_ternary_conversion_verifier_oracle import expected_output as independent_output

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/b/balanced_ternary_conversion"
PORTS = {
    "c": ROOT / "c/b/balanced_ternary_conversion.c",
    "c3": ROOT / "c3/b/balanced_ternary_conversion.c3",
    "cpp": ROOT / "cpp/b/balanced_ternary_conversion.cpp",
    "elisa": ROOT / "elisa/b/balanced_ternary_conversion.elisa",
    "mojo": ROOT / "mojo/b/balanced_ternary_conversion.mojo",
    "nim": ROOT / "nim/b/balanced_ternary_conversion.nim",
    "odin": ROOT / "odin/b/balanced_ternary_conversion.odin",
    "rust": ROOT / "rust/b/balanced_ternary_conversion.rs",
    "v": ROOT / "v/b/balanced_ternary_conversion.v",
    "zig": ROOT / "zig/b/balanced_ternary_conversion.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    if workload.get("algorithm") != "balanced_ternary_conversion":
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != "balanced_ternary_conversion":
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("unexpected ABI")
    input_contract = workload.get("input", {})
    if input_contract.get("exact_length") != 1:
        issues.append("input length mismatch")
    if input_contract.get("maximum_valid_length") != 1 or input_contract.get("maximum_parseable_length") != 2:
        issues.append("maximum input length mismatch")
    output_contract = workload.get("output", {})
    if output_contract.get("maximum_bytes") != 41:
        issues.append("maximum output size mismatch")
    if workload.get("workspace", {}).get("bytes", 0) < 41:
        issues.append("workspace output capacity is too small")

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
        arguments = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = (case.get("expected_result"), bytes.fromhex(case.get("expected_output_hex", "")))
        if primary_output(values, **arguments) != expected:
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if independent_output(values, **arguments) != expected:
            issues.append(f"independent oracle fixture mismatch: {case_id}")

    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "balanced_ternary_conversion" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    if "https://cp-algorithms.com/algebra/balanced-ternary.html" not in readme:
        issues.append("README missing algorithm source")
    elisa = PORTS["elisa"]
    if elisa.is_file():
        source = elisa.read_text(encoding="utf-8")
        if ("input: view[i64]" not in source or "output: mutable view[u8]" not in source
                or "input: i64&" not in source or "output: mutable u8&" not in source):
            issues.append("Elisa must use internal safe views and refs only at the exported ABI")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
