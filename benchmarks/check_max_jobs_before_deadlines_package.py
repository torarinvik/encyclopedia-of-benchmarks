"""Static inventory and fixture review for max-jobs-before-deadlines ports."""

from __future__ import annotations

import json
from pathlib import Path

from max_jobs_before_deadlines_oracle import expected_result as primary_result
from max_jobs_before_deadlines_verifier_oracle import expected_result as independent_result

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/d/max_jobs_before_deadlines"
PORTS = {
    "c": ROOT / "c/d/max_jobs_before_deadlines.c",
    "c3": ROOT / "c3/d/max_jobs_before_deadlines.c3",
    "cpp": ROOT / "cpp/d/max_jobs_before_deadlines.cpp",
    "elisa": ROOT / "elisa/d/max_jobs_before_deadlines.elisa",
    "mojo": ROOT / "mojo/d/max_jobs_before_deadlines.mojo",
    "nim": ROOT / "nim/d/max_jobs_before_deadlines.nim",
    "odin": ROOT / "odin/d/max_jobs_before_deadlines.odin",
    "rust": ROOT / "rust/d/max_jobs_before_deadlines.rs",
    "v": ROOT / "v/d/max_jobs_before_deadlines.v",
    "zig": ROOT / "zig/d/max_jobs_before_deadlines.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if workload.get("algorithm") != "max_jobs_before_deadlines":
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != "max_jobs_before_deadlines":
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("unexpected ABI")
    input_contract = workload.get("input", {})
    if input_contract.get("job_count_range") != [0, 12]:
        issues.append("job-count bounds mismatch")
    if input_contract.get("deadline_range") != [0, 1000]:
        issues.append("deadline bounds mismatch")
    if input_contract.get("duration_range") != [1, 1000]:
        issues.append("duration bounds mismatch")
    if input_contract.get("maximum_valid_length") != 25:
        issues.append("maximum input length mismatch")
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
        elif "max_jobs_before_deadlines" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    if "https://cp-algorithms.com/schedules/schedule-with-completion-duration.html" not in readme:
        issues.append("README missing algorithm source")
    elisa = PORTS["elisa"]
    if elisa.is_file():
        source = elisa.read_text(encoding="utf-8")
        if "input_view: view[i64]" not in source or "input: i64&" not in source:
            issues.append("Elisa must use a safe input view internally and a ref only at the exported ABI")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
