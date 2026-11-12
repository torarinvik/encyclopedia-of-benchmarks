"""Static inventory and fixture review for Johnson two-machine flow-shop ports."""

from __future__ import annotations

import json
from pathlib import Path

from johnson_two_machine_flow_shop_oracle import expected_result as primary_result
from johnson_two_machine_flow_shop_verifier_oracle import expected_result as independent_result

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/j/johnson_two_machine_flow_shop"
PORTS = {
    "c": ROOT / "c/j/johnson_two_machine_flow_shop.c",
    "c3": ROOT / "c3/j/johnson_two_machine_flow_shop.c3",
    "cpp": ROOT / "cpp/j/johnson_two_machine_flow_shop.cpp",
    "elisa": ROOT / "elisa/j/johnson_two_machine_flow_shop.elisa",
    "mojo": ROOT / "mojo/j/johnson_two_machine_flow_shop.mojo",
    "nim": ROOT / "nim/j/johnson_two_machine_flow_shop.nim",
    "odin": ROOT / "odin/j/johnson_two_machine_flow_shop.odin",
    "rust": ROOT / "rust/j/johnson_two_machine_flow_shop.rs",
    "v": ROOT / "v/j/johnson_two_machine_flow_shop.v",
    "zig": ROOT / "zig/j/johnson_two_machine_flow_shop.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    if workload.get("algorithm") != "johnson_two_machine_flow_shop":
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != "johnson_two_machine_flow_shop":
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("unexpected ABI")
    if workload.get("input", {}).get("job_count_range") != [1, 8]:
        issues.append("job-count bounds mismatch")
    if workload.get("input", {}).get("processing_time_range") != [0, 1000]:
        issues.append("processing-time bounds mismatch")

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
        expected = case.get("expected_result")
        if primary_result(values) != expected:
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if independent_result(values) != expected:
            issues.append(f"independent oracle fixture mismatch: {case_id}")

    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "johnson_two_machine_flow_shop" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    if "https://cp-algorithms.com/schedules/schedule_two_machines.html" not in readme:
        issues.append("README missing algorithm source")
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
