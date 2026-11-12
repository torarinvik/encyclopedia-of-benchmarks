"""Static inventory and fixture review for the Kahan summation package."""

from __future__ import annotations

import json
from pathlib import Path

from kahan_summation_oracle import expected_abi
from kahan_summation_verifier_oracle import verify_result

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/k/kahan_summation"
LANGUAGE_PATHS = {
    "c": ROOT / "c/k/kahan_summation.c",
    "c3": ROOT / "c3/k/kahan_summation.c3",
    "cpp": ROOT / "cpp/k/kahan_summation.cpp",
    "elisa": ROOT / "elisa/k/kahan_summation.elisa",
    "mojo": ROOT / "mojo/k/kahan_summation.mojo",
    "nim": ROOT / "nim/k/kahan_summation.nim",
    "odin": ROOT / "odin/k/kahan_summation.odin",
    "rust": ROOT / "rust/k/kahan_summation.rs",
    "v": ROOT / "v/k/kahan_summation.v",
    "zig": ROOT / "zig/k/kahan_summation.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    if workload.get("algorithm") != "kahan_summation":
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != "kahan_summation":
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "float64_slice_io":
        issues.append("unexpected ABI")
    input_meta = workload.get("input", {})
    if input_meta.get("maximum_input_length") != 256 or input_meta.get("maximum_absolute_value") != 1e100:
        issues.append("bounded input contract mismatch")
    if workload.get("output", {}).get("maximum_elements") != 1:
        issues.append("output capacity contract mismatch")
    if workload.get("workspace", {}).get("elements") != 2:
        issues.append("summation workspace contract mismatch")
    if workload.get("measurement", {}).get("comparison_model") != "float64_slice_io_call":
        issues.append("unexpected measurement model")

    for case in workload.get("cases", []):
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        values = case.get("input_values")
        result, output = expected_abi(
            values,
            output_capacity=case.get("output_capacity"),
            output_is_null=case.get("output_is_null", False),
            input_is_null=case.get("input_is_null", False),
            input_length=case.get("input_length"),
        )
        case_id = case.get("id", "<unnamed>")
        if result != case.get("expected_result") or output != case.get("expected_output"):
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if not verify_result(
            values,
            result,
            output,
            output_capacity=case.get("output_capacity"),
            output_is_null=case.get("output_is_null", False),
            input_is_null=case.get("input_is_null", False),
            input_length=case.get("input_length"),
        ):
            issues.append(f"independent verifier rejected fixture: {case_id}")

    for language, path in LANGUAGE_PATHS.items():
        if not path.is_file():
            issues.append(f"missing {language} source: {path.relative_to(ROOT)}")
        elif "kahan_summation" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text in {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")
    if not (ROOT / "benchmarks/kahan_summation_oracle.py").is_file():
        issues.append("missing primary oracle")
    if not (ROOT / "benchmarks/kahan_summation_verifier_oracle.py").is_file():
        issues.append("missing independent verifier")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
