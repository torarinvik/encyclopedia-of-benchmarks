"""Static ten-port inventory and package fixture consistency checks."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
from types import ModuleType

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/s/super_stable_matching_ties_incomplete.c",
    "c3": "c3/s/super_stable_matching_ties_incomplete.c3",
    "cpp": "cpp/s/super_stable_matching_ties_incomplete.cpp",
    "elisa": "elisa/s/super_stable_matching_ties_incomplete.elisa",
    "mojo": "mojo/s/super_stable_matching_ties_incomplete.mojo",
    "nim": "nim/s/super_stable_matching_ties_incomplete.nim",
    "odin": "odin/s/super_stable_matching_ties_incomplete.odin",
    "rust": "rust/s/super_stable_matching_ties_incomplete.rs",
    "v": "v/s/super_stable_matching_ties_incomplete.v",
    "zig": "zig/s/super_stable_matching_ties_incomplete.zig",
}
NULL_GUARDS = {
    "c": "input == NULL",
    "c3": "input == null",
    "cpp": "input == nullptr",
    "elisa": "input.is_null()",
    "mojo": "input == UnsafePointer[Int64, ImmutAnyOrigin]()",
    "nim": "input == nil",
    "odin": "input == nil",
    "rust": "input.is_null()",
    "v": "input == nil",
    "zig": "input == null",
}
EXPECTED_CASES = {
    "single-mutual-pair", "incomplete-single-pair", "empty-lists-no-proposals",
    "strict-successor-deletion", "one-sided-tie-super-stable",
    "strict-successor-unengaged-tail-pruning",
    "all-ties-no-super-stable-matching", "maximum-n-empty-instance",
    "maximum-dense-frame-all-tied", "invalid-n-zero",
    "invalid-asymmetric-acceptability", "invalid-rank-gap", "trailing-word",
    "null-input-zero-length", "null-input-maximum-parseable-length",
}
PROVENANCE_URLS = (
    "https://www.dcs.gla.ac.uk/~davidm/pubs/6497.pdf",
    "https://doi.org/10.1007/978-1-4939-2864-4_805",
)


def _load_oracle(name: str) -> ModuleType:
    spec = importlib.util.spec_from_file_location(name, PACKAGE / f"{name}.py")
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load {name}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    primary = _load_oracle("primary_oracle")
    independent = _load_oracle("independent_oracle")
    if (workload.get("algorithm") != "super_stable_matching_ties_incomplete"
            or workload.get("function_symbol") != "super_stable_matching_ties_incomplete"
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("algorithm identity, symbol, or ABI mismatch")
    input_spec = workload.get("input", {})
    if (input_spec.get("n_range") != [1, primary.MAX_N]
            or input_spec.get("maximum_valid_length") != primary.MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != primary.MAX_PARSEABLE_INPUT_LENGTH):
        issues.append("workload input bounds differ from primary oracle")
    output_spec = workload.get("output", {})
    if output_spec.get("valid_result_range") != [-2, (primary.MAX_N + 1) ** primary.MAX_N - 1]:
        issues.append("workload output range mismatch")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not all(isinstance(case, dict) for case in cases):
        return issues + ["workload cases must be a list of objects"]
    case_ids = {case.get("id") for case in cases}
    if len(case_ids) != len(cases) or case_ids != EXPECTED_CASES:
        issues.append("fixture IDs are duplicated or differ from the reviewed inventory")
    for case in cases:
        case_id = case.get("id", "<unnamed>")
        values = case.get("input_values")
        input_is_null = case.get("input_is_null", False)
        input_length = case.get("input_length")
        if (not isinstance(values, list) or type(input_is_null) is not bool
                or type(input_length) is not int
                or (input_is_null and (values or not 0 <= input_length <= primary.MAX_PARSEABLE_INPUT_LENGTH))
                or (not input_is_null and input_length != len(values))):
            issues.append(f"input frame length mismatch: {case_id}")
            continue
        arguments = {
            "input_is_null": input_is_null,
            "input_length": input_length,
        }
        expected = case.get("expected_result")
        if primary.expected_result(values, **arguments) != expected:
            issues.append(f"primary fixture result mismatch: {case_id}")
        if independent.expected_result(values, **arguments) != expected:
            issues.append(f"independent fixture result mismatch: {case_id}")

    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "check_inventory.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    except OSError as error:
        return issues + [f"cannot read package documentation: {error}"]
    for language, relative in PORTS.items():
        source_path = ROOT / relative
        if not source_path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        source = source_path.read_text(encoding="utf-8")
        if "super_stable_matching_ties_incomplete" not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"null guard missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README source link mismatch for {language}")
    elisa = (ROOT / PORTS["elisa"]).read_text(encoding="utf-8")
    if "input: view[i64]" not in elisa or "UnsafePointer" in elisa or "*i64" in elisa:
        issues.append("Elisa port should use a view internally and avoid raw pointers")
    for url in PROVENANCE_URLS:
        if url not in readme or url not in rights:
            issues.append(f"provenance URL missing from README or RIGHTS: {url}")
    return issues


def verify() -> None:
    """Raise if static port inventory or fixture expectations are incomplete."""
    issues = static_issues()
    if issues:
        raise ValueError("\n".join(issues))
