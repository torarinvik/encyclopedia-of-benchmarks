"""Static package inventory and oracle review; this checker launches no ports."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/h/hirschberg_lcs"

from h.hirschberg_lcs.independent_oracle import (
    expected_output as independent_expected_output,
    verify_output,
)
from h.hirschberg_lcs.primary_oracle import WORKSPACE_BYTES, expected_output

LANGUAGE_PATHS = {
    "c": ROOT / "c/h/hirschberg_lcs.c",
    "c3": ROOT / "c3/h/hirschberg_lcs.c3",
    "cpp": ROOT / "cpp/h/hirschberg_lcs.cpp",
    "elisa": ROOT / "elisa/h/hirschberg_lcs.elisa",
    "mojo": ROOT / "mojo/h/hirschberg_lcs.mojo",
    "nim": ROOT / "nim/h/hirschberg_lcs.nim",
    "odin": ROOT / "odin/h/hirschberg_lcs.odin",
    "rust": ROOT / "rust/h/hirschberg_lcs.rs",
    "v": ROOT / "v/h/hirschberg_lcs.v",
    "zig": ROOT / "zig/h/hirschberg_lcs.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    if workload.get("algorithm") != "hirschberg_lcs":
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != "hirschberg_lcs":
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("unexpected ABI")
    input_meta = workload.get("input", {})
    if input_meta.get("sequence_length_range") != [0, 64] or input_meta.get("symbol_range") != [0, 127]:
        issues.append("input bounds mismatch")
    if input_meta.get("maximum_valid_length") != 130 or input_meta.get("maximum_parseable_length") != 132:
        issues.append("input frame bounds mismatch")
    if workload.get("output", {}).get("maximum_output_bytes") != 64:
        issues.append("maximum output bound mismatch")
    if workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES:
        issues.append("workspace bound mismatch")
    if workload.get("measurement", {}).get("comparison_model") != "i64_array_bytes_output_call":
        issues.append("unexpected measurement model")

    cases = workload.get("cases", [])
    if not isinstance(cases, list):
        return issues + ["workload cases must be a list"]
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        options = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        values = case.get("input_values")
        case_id = case.get("id", "<unnamed>")
        expected = (case.get("expected_result"), bytes.fromhex(case.get("expected_output_hex", "")))
        primary = expected_output(values, **options)
        if primary != expected:
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        try:
            independent = independent_expected_output(values, **options)
        except ValueError:
            issues.append(f"independent full-table oracle rejected primary result: {case_id}")
        else:
            if independent != expected:
                issues.append(f"independent oracle fixture mismatch: {case_id}")
        if not verify_output(values, *primary, **options):
            issues.append(f"independent optimality verifier rejected case: {case_id}")

    for language, path in LANGUAGE_PATHS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "hirschberg_lcs" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    if "10.1145/360825.360861" not in readme or "smallest" not in readme:
        issues.append("README is missing provenance or deterministic tie policy")
    elisa = LANGUAGE_PATHS["elisa"].read_text(encoding="utf-8")
    if "view[i64]" not in elisa or "input: i64&" not in elisa:
        issues.append("Elisa must use safe views internally and refs only at the ABI")
    for name in ("hirschberg_lcs_oracle.py", "hirschberg_lcs_verifier_oracle.py"):
        if not (ROOT / "benchmarks" / name).is_file():
            issues.append(f"missing shared-suite oracle entry point: {name}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
