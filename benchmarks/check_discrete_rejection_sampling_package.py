"""Static inventory, metadata, and fixture review for this package."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/d/discrete_rejection_sampling"

from d.discrete_rejection_sampling.independent_oracle import expected_output as independent_output
from d.discrete_rejection_sampling.primary_oracle import (
    MAX_INPUT_LENGTH,
    MAX_OUTPUT_BYTES,
    WORKSPACE_BYTES,
    expected_output as primary_output,
)

LANGUAGE_PATHS = {
    "c": ROOT / "c/d/discrete_rejection_sampling.c",
    "c3": ROOT / "c3/d/discrete_rejection_sampling.c3",
    "cpp": ROOT / "cpp/d/discrete_rejection_sampling.cpp",
    "elisa": ROOT / "elisa/d/discrete_rejection_sampling.elisa",
    "mojo": ROOT / "mojo/d/discrete_rejection_sampling.mojo",
    "nim": ROOT / "nim/d/discrete_rejection_sampling.nim",
    "odin": ROOT / "odin/d/discrete_rejection_sampling.odin",
    "rust": ROOT / "rust/d/discrete_rejection_sampling.rs",
    "v": ROOT / "v/d/discrete_rejection_sampling.v",
    "zig": ROOT / "zig/d/discrete_rejection_sampling.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    if workload.get("algorithm") != "discrete_rejection_sampling":
        issues.append("algorithm name mismatch")
    if workload.get("function_symbol") != "discrete_rejection_sampling":
        issues.append("exported symbol mismatch")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("ABI mismatch")
    input_meta = workload.get("input", {})
    if input_meta.get("category_count_range") != [1, 8] or input_meta.get("samples_wanted_range") != [1, 8]:
        issues.append("category or sample bounds mismatch")
    if input_meta.get("attempt_cap_range") != [1, 32] or input_meta.get("weight_range") != [1, 20]:
        issues.append("attempt or weight bounds mismatch")
    if input_meta.get("maximum_valid_input_length") != MAX_INPUT_LENGTH:
        issues.append("maximum input length differs from the oracle")
    if input_meta.get("maximum_parseable_input_length") != MAX_INPUT_LENGTH:
        issues.append("maximum parseable length differs from the oracle")
    output_meta = workload.get("output", {})
    if output_meta.get("maximum_output_bytes") != MAX_OUTPUT_BYTES:
        issues.append("maximum output bytes differ from the oracle")
    if workload.get("workspace", {}).get("bytes", 0) != WORKSPACE_BYTES:
        issues.append("workspace metadata differs from the oracle")
    if workload.get("workspace", {}).get("bytes", 0) < output_meta.get("maximum_output_bytes", 1 << 60):
        issues.append("workspace must be at least the maximum output capacity")
    semantics = workload.get("semantics", {})
    if not semantics.get("envelope") or not semantics.get("proposal_step") or not semantics.get("acceptance_step"):
        issues.append("workload omits proposal or acceptance semantics")
    if input_meta.get("exhausted_attempt_tape_result") != -3:
        issues.append("exhaustion result mismatch")
    if "i64_array_bytes_output_call" != workload.get("measurement", {}).get("comparison_model"):
        issues.append("measurement model mismatch")

    cases = workload.get("cases", [])
    if not isinstance(cases, list):
        return issues + ["workload cases must be a list"]
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        values = case.get("input_values")
        options = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = (case.get("expected_result"), bytes.fromhex(case.get("expected_output_hex", "")))
        case_id = case.get("id", "<unnamed>")
        if primary_output(values, **options) != expected:
            issues.append(f"primary fixture mismatch: {case_id}")
        if independent_output(values, **options) != expected:
            issues.append(f"independent fixture mismatch: {case_id}")
        if isinstance(values, list) and case.get("id") == "maximum-input-profile" and len(values) != MAX_INPUT_LENGTH:
            issues.append("maximum-input fixture does not use the declared input bound")
        if case.get("id") == "maximum-output-profile":
            if case.get("expected_result") != MAX_OUTPUT_BYTES:
                issues.append("maximum-output fixture does not return the declared output bound")
            if len(case.get("expected_output_hex", "")) != 2 * MAX_OUTPUT_BYTES:
                issues.append("maximum-output fixture does not encode the full output bound")

    for language, path in LANGUAGE_PATHS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "discrete_rejection_sampling" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for artifact in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / artifact).is_file():
            issues.append(f"missing package artifact: {artifact}")
    for artifact in ("discrete_rejection_sampling_oracle.py", "discrete_rejection_sampling_verifier_oracle.py"):
        if not (ROOT / "benchmarks" / artifact).is_file():
            issues.append(f"missing suite oracle entry point: {artifact}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    ledger = (ROOT / "benchmarks/ALGORITHM_EXPANSION_COVERAGE.md").read_text(encoding="utf-8")
    if "10.1007/978-1-4613-8643-8_2" not in readme or "Devroye" not in readme:
        issues.append("README is missing the algorithm source")
    if "10.1007/978-1-4613-8643-8_2" not in rights or "independently written" not in rights:
        issues.append("rights note is missing source or clean-room statement")
    if "[`discrete_rejection_sampling`](d/discrete_rejection_sampling/README.md)" not in ledger:
        issues.append("coverage ledger is missing this algorithm entry")
    elisa = LANGUAGE_PATHS["elisa"].read_text(encoding="utf-8")
    if "view[i64]" not in elisa or "input: i64&" not in elisa:
        issues.append("Elisa should use safe views internally and ABI refs only")
    if elisa.count("&") != 2:
        issues.append("Elisa contains a non-ABI raw reference")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
