"""Static inventory and fixture review for temporary-task load balancing."""

from __future__ import annotations

import json
from pathlib import Path

from online_temporary_task_load_balancing_oracle import expected_output as primary_output
from online_temporary_task_load_balancing_verifier_oracle import expected_output as independent_output

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/o/online_temporary_task_load_balancing"
PORTS = {
    "c": ROOT / "c/o/online_temporary_task_load_balancing.c",
    "c3": ROOT / "c3/o/online_temporary_task_load_balancing.c3",
    "cpp": ROOT / "cpp/o/online_temporary_task_load_balancing.cpp",
    "elisa": ROOT / "elisa/o/online_temporary_task_load_balancing.elisa",
    "mojo": ROOT / "mojo/o/online_temporary_task_load_balancing.mojo",
    "nim": ROOT / "nim/o/online_temporary_task_load_balancing.nim",
    "odin": ROOT / "odin/o/online_temporary_task_load_balancing.odin",
    "rust": ROOT / "rust/o/online_temporary_task_load_balancing.rs",
    "v": ROOT / "v/o/online_temporary_task_load_balancing.v",
    "zig": ROOT / "zig/o/online_temporary_task_load_balancing.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    if workload.get("algorithm") != "online_temporary_task_load_balancing":
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != "online_temporary_task_load_balancing":
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("unexpected ABI")
    input_contract = workload.get("input", {})
    if input_contract.get("maximum_valid_length") != 98 or input_contract.get("maximum_parseable_length") != 99:
        issues.append("maximum input length mismatch")
    if input_contract.get("active_interval") != "[arrival, arrival + duration)":
        issues.append("task activity interval mismatch")
    output_contract = workload.get("output", {})
    if output_contract.get("maximum_bytes") != 264:
        issues.append("maximum output size mismatch")
    if workload.get("workspace", {}).get("bytes", 0) < 264:
        issues.append("workspace is smaller than maximum output capacity")

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
        try:
            expected = (case.get("expected_result"), bytes.fromhex(case.get("expected_output_hex", "")))
        except (TypeError, ValueError):
            issues.append(f"fixture output hex is invalid: {case_id}")
            continue
        if primary_output(values, **arguments) != expected:
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if independent_output(values, **arguments) != expected:
            issues.append(f"independent oracle fixture mismatch: {case_id}")

    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "online_temporary_task_load_balancing" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    if "10.1007/978-1-4939-2864-4_206" not in readme:
        issues.append("README missing source attribution")
    if "completion-before-arrival" not in json.dumps(cases):
        issues.append("workload does not exercise completion-before-arrival ordering")
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
