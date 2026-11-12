"""Static inventory and fixture review for dynamic MEX update ports."""

from __future__ import annotations

import json
from pathlib import Path

from dynamic_mex_updates_oracle import expected_output as primary_output
from dynamic_mex_updates_verifier_oracle import expected_output as independent_output

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/d/dynamic_mex_updates"
PORTS = {
    "c": ROOT / "c/d/dynamic_mex_updates.c",
    "c3": ROOT / "c3/d/dynamic_mex_updates.c3",
    "cpp": ROOT / "cpp/d/dynamic_mex_updates.cpp",
    "elisa": ROOT / "elisa/d/dynamic_mex_updates.elisa",
    "mojo": ROOT / "mojo/d/dynamic_mex_updates.mojo",
    "nim": ROOT / "nim/d/dynamic_mex_updates.nim",
    "odin": ROOT / "odin/d/dynamic_mex_updates.odin",
    "rust": ROOT / "rust/d/dynamic_mex_updates.rs",
    "v": ROOT / "v/d/dynamic_mex_updates.v",
    "zig": ROOT / "zig/d/dynamic_mex_updates.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if workload.get("algorithm") != "dynamic_mex_updates":
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != "dynamic_mex_updates":
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("unexpected ABI")
    input_contract = workload.get("input", {})
    if input_contract.get("N_range") != [1, 32] or input_contract.get("Q_range") != [0, 32]:
        issues.append("N/Q bounds mismatch")
    if input_contract.get("value_range") != [-1000, 1000]:
        issues.append("value bounds mismatch")
    if input_contract.get("maximum_valid_length") != 98:
        issues.append("maximum valid input length mismatch")
    if input_contract.get("maximum_parseable_length") != 99:
        issues.append("maximum parseable input length mismatch")
    output_contract = workload.get("output", {})
    if output_contract.get("maximum_bytes") != 256:
        issues.append("maximum output size mismatch")
    if workload.get("workspace", {}).get("bytes", 0) < 256:
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
        arguments = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
        }
        expected = (case.get("expected_result"), bytes.fromhex(case.get("expected_output_hex", "")))
        if primary_output(values, **arguments) != expected:
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if independent_output(values, **arguments) != expected:
            issues.append(f"independent oracle fixture mismatch: {case_id}")

    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "dynamic_mex_updates" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    if "https://cp-algorithms.com/sequences/mex.html" not in readme:
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
