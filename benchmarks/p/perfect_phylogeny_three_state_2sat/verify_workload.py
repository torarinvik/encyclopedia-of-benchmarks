"""Static consistency review for the bounded Chapter 288 workload."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
from types import ModuleType

PACKAGE = Path(__file__).resolve().parent
EXPECTED_CASES = {
    "empty-character-family",
    "one-taxon-single-observed-state-character",
    "all-states-observed-identical-partitions",
    "two-state-compatible-nested-splits",
    "embedded-three-character-binary-obstruction",
    "maximum-valid-all-zero-matrix",
    "invalid-state-value",
    "invalid-frame-shape",
    "null-input",
    "maximum-parseable-trailing-word",
}


def _load_oracle(name: str) -> ModuleType:
    spec = importlib.util.spec_from_file_location(name, PACKAGE / f"{name}.py")
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load package reference {name}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def workload_issues() -> list[str]:
    """Return package workload/reference mismatches without invoking native code."""
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    primary = _load_oracle("primary_oracle")
    independent = _load_oracle("independent_oracle")
    issues: list[str] = []
    if workload.get("algorithm") != "perfect_phylogeny_three_state_2sat":
        issues.append("workload algorithm identity mismatch")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("workload ABI mismatch")
    input_spec = workload.get("input", {})
    if (input_spec.get("maximum_valid_length") != primary.MAX_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != primary.MAX_PARSEABLE_INPUT_LENGTH
            or input_spec.get("taxa_range") != [1, primary.MAX_TAXA]
            or input_spec.get("character_range") != [0, primary.MAX_CHARACTERS]
            or input_spec.get("observed_state_count_range_per_character") != [1, 3]
            or input_spec.get("zero_characters") is None):
        issues.append("workload input bounds differ from the primary reference")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not all(isinstance(case, dict) for case in cases):
        return issues + ["workload cases must be a list of objects"]
    case_ids = {case.get("id") for case in cases}
    if len(case_ids) != len(cases) or case_ids != EXPECTED_CASES:
        issues.append("fixture IDs are duplicated or differ from the reviewed set")
    for case in cases:
        case_id = case.get("id", "<unnamed>")
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"fixture frame length mismatch: {case_id}")
            continue
        if len(values) > primary.MAX_PARSEABLE_INPUT_LENGTH:
            issues.append(f"fixture exceeds parseable input bound: {case_id}")
            continue
        arguments = {
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = case.get("expected_result")
        if primary.expected_result(values, **arguments) != expected:
            issues.append(f"primary-reference result mismatch: {case_id}")
        if independent.expected_result(values, **arguments) != expected:
            issues.append(f"independent-reference result mismatch: {case_id}")
    return issues


def verify() -> None:
    issues = workload_issues()
    if issues:
        raise ValueError("\n".join(issues))
