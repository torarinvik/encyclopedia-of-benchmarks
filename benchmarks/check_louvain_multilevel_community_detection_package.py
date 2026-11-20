"""Static inventory for the bounded Louvain package."""

from __future__ import annotations

import json
from pathlib import Path

from louvain_multilevel_community_detection_oracle import expected_result as primary_result
from louvain_multilevel_community_detection_verifier_oracle import expected_result as independent_result

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/l/louvain_multilevel_community_detection"
SYMBOL = "louvain_multilevel_community_detection"
PORTS = {
    "c": ROOT / "c/l/louvain_multilevel_community_detection.c",
    "c3": ROOT / "c3/l/louvain_multilevel_community_detection.c3",
    "cpp": ROOT / "cpp/l/louvain_multilevel_community_detection.cpp",
    "elisa": ROOT / "elisa/l/louvain_multilevel_community_detection.elisa",
    "mojo": ROOT / "mojo/l/louvain_multilevel_community_detection.mojo",
    "nim": ROOT / "nim/l/louvain_multilevel_community_detection.nim",
    "odin": ROOT / "odin/l/louvain_multilevel_community_detection.odin",
    "rust": ROOT / "rust/l/louvain_multilevel_community_detection.rs",
    "v": ROOT / "v/l/louvain_multilevel_community_detection.v",
    "zig": ROOT / "zig/l/louvain_multilevel_community_detection.zig",
}


def _maximum_case() -> tuple[int, ...]:
    return (8, 28, *(value for u in range(8) for v in range(u + 1, 8) for value in (u, v, 7)))


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
    output = workload.get("output", {})
    if contract.get("maximum_valid_length") != 86 or contract.get("maximum_parseable_length") != 87:
        issues.append("maximum input length mismatch")
    if output.get("maximum_result_bound") != 150_994_943:
        issues.append("maximum result bound mismatch")
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
            issues.append(f"quotient-matrix oracle fixture mismatch: {case_id}")
        if independent_result(values, **arguments) != expected:
            issues.append(f"original-graph oracle fixture mismatch: {case_id}")

    maximum = _maximum_case()
    if len(maximum) != 86:
        issues.append("maximum input construction mismatch")
    elif primary_result(maximum) != 16_777_216 or independent_result(maximum) != 16_777_216:
        issues.append("maximum complete-graph checksum mismatch")
    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    if "10.1088/1742-5468/2008/10/P10008" not in readme:
        issues.append("README missing source attribution")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
