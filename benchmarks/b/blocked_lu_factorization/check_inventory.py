"""Static inventory and workload-contract checks for blocked LU."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
ALGORITHM = "blocked_lu_factorization"
PORTS = {
    "c": ROOT / "c/b/blocked_lu_factorization.c",
    "c3": ROOT / "c3/b/blocked_lu_factorization.c3",
    "cpp": ROOT / "cpp/b/blocked_lu_factorization.cpp",
    "elisa": ROOT / "elisa/b/blocked_lu_factorization.elisa",
    "mojo": ROOT / "mojo/b/blocked_lu_factorization.mojo",
    "nim": ROOT / "nim/b/blocked_lu_factorization.nim",
    "odin": ROOT / "odin/b/blocked_lu_factorization.odin",
    "rust": ROOT / "rust/b/blocked_lu_factorization.rs",
    "v": ROOT / "v/b/blocked_lu_factorization.v",
    "zig": ROOT / "zig/b/blocked_lu_factorization.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    workload_path = PACKAGE / "workload.json"
    try:
        workload = json.loads(workload_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read valid workload.json: {error}"]

    if workload.get("algorithm") != ALGORITHM or workload.get("function_symbol") != ALGORITHM:
        issues.append("workload algorithm and exported symbol must match the package")
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if input_spec.get("maximum_valid_input_length") != 65:
        issues.append("maximum valid input length must be 65")
    if input_spec.get("maximum_parseable_input_length") != 66:
        issues.append("maximum parseable input length must be 66")
    if output_spec.get("maximum_elements") != 128 or output_spec.get("maximum_bytes") != 1024:
        issues.append("maximum output must be 128 float64 values / 1024 bytes")
    if (workload.get("workspace", {}).get("elements") != 128
            or workload.get("workspace", {}).get("bytes") != 2560):
        issues.append("workspace must account for 320 float64 values")

    cases = workload.get("cases")
    abi_cases = workload.get("abi_cases")
    if not isinstance(cases, list) or not isinstance(abi_cases, list):
        issues.append("workload must have cases and abi_cases arrays")
        cases, abi_cases = [], []
    for case in cases:
        if not isinstance(case, dict):
            issues.append("a workload case is not an object")
            continue
        values = case.get("input_values")
        output = case.get("expected_output")
        result = case.get("expected_result")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"{case.get('id', '<unnamed>')}: input framing mismatch")
        if not isinstance(output, list) or type(result) is not int or len(output) != result:
            issues.append(f"{case.get('id', '<unnamed>')}: success output/result mismatch")
        if isinstance(output, list) and any(type(x) not in (int, float) for x in output):
            issues.append(f"{case.get('id', '<unnamed>')}: output contains a non-number")
        if isinstance(values, list) and len(values) > 65:
            issues.append(f"{case.get('id', '<unnamed>')}: input exceeds the valid bound")
    for case in abi_cases:
        if not isinstance(case, dict):
            issues.append("an ABI case is not an object")
            continue
        values = case.get("input_values")
        output = case.get("expected_output")
        result = case.get("expected_result")
        if not isinstance(values, list) or not isinstance(output, list):
            issues.append(f"{case.get('id', '<unnamed>')}: ABI values/output must be arrays")
            continue
        if result >= 0 and len(output) != result:
            issues.append(f"{case.get('id', '<unnamed>')}: ABI success output/result mismatch")
        if result < 0 and output:
            issues.append(f"{case.get('id', '<unnamed>')}: error case must have empty output")

    if not any(case.get("input_length") == 65 and case.get("expected_result") == 128
               for case in cases if isinstance(case, dict)):
        issues.append("maximum workload case must cover the 65-word input and 128-value output")

    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
            continue
        source = path.read_text(encoding="utf-8")
        if ALGORITHM not in source:
            issues.append(f"{language} port does not contain the exported ABI symbol")
    for name in ("README.md", "RIGHTS.md"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package metadata: {name}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        for problem in problems:
            print(problem)
        raise SystemExit(1)
    print("blocked_lu_factorization static inventory is complete")
