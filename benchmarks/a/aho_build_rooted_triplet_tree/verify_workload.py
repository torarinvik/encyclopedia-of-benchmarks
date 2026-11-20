"""Static workload and reference crosswalk helper; intentionally not run here."""

from __future__ import annotations

import json
import importlib.util
from pathlib import Path
from types import ModuleType

PACKAGE = Path(__file__).resolve().parent

def _load_reference(name: str) -> ModuleType:
    spec = importlib.util.spec_from_file_location(name, PACKAGE / f"{name}.py")
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load package reference {name}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def workload_issues() -> list[str]:
    issues: list[str] = []
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    primary = _load_reference("primary_oracle")
    independent = _load_reference("independent_oracle")
    if workload.get("algorithm") != "aho_build_rooted_triplet_tree":
        issues.append("workload algorithm identity mismatch")
    if workload.get("input", {}).get("maximum_valid_length") != primary.MAX_VALID_INPUT_LENGTH:
        issues.append("maximum valid input length mismatch")
    if workload.get("input", {}).get("maximum_parseable_length") != primary.MAX_PARSEABLE_INPUT_LENGTH:
        issues.append("maximum parseable input length mismatch")
    if workload.get("output", {}).get("maximum_output_bytes") != primary.MAX_OUTPUT_BYTES:
        issues.append("maximum output bound mismatch")
    if workload.get("workspace", {}).get("bytes") != primary.WORKSPACE_BYTES:
        issues.append("workspace bound mismatch")
    case_ids: set[str] = set()
    for case in workload.get("cases", []):
        case_id = case.get("id")
        if not isinstance(case_id, str) or case_id in case_ids:
            issues.append("workload case IDs must be unique strings")
            continue
        case_ids.add(case_id)
        kwargs = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        if kwargs["input_is_null"]:
            values = None
        else:
            values = case.get("input_values")
        expected = primary.expected_output(values, **kwargs)
        other = independent.expected_output(values, **kwargs)
        if expected != other:
            issues.append(f"reference disagreement in {case_id}")
        if expected[0] != case.get("expected_result"):
            issues.append(f"result mismatch in {case_id}")
        if expected[1].hex() != case.get("expected_output_hex"):
            issues.append(f"payload mismatch in {case_id}")
    return issues

