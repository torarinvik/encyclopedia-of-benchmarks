"""Static fixture/reference reconciler; intentionally not run during drafting."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent


def _load(name: str):
    spec = importlib.util.spec_from_file_location(name, PACKAGE / f"{name}.py")
    if spec is None or spec.loader is None:
        raise OSError(f"cannot load {name}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def workload_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        primary = _load("primary_oracle")
        independent = _load("independent_oracle")
    except (OSError, json.JSONDecodeError, ImportError) as error:
        return [f"workload or references are unreadable: {error}"]
    for case in workload.get("cases", []):
        name = case.get("id", "<unnamed>")
        values = case.get("input_values")
        flags = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected_result = case.get("expected_result")
        expected_hex = case.get("expected_output_hex")
        try:
            expected_bytes = bytes.fromhex(expected_hex)
            primary_result = primary.expected_output(values, **flags)
            independent_result = independent.expected_output(values, **flags)
        except (TypeError, ValueError, IndexError) as error:
            issues.append(f"{name}: malformed fixture or reference call: {error}")
            continue
        pinned = (expected_result, expected_bytes)
        if primary_result != pinned:
            issues.append(f"{name}: primary reference differs from pinned result")
        if independent_result != pinned:
            issues.append(f"{name}: independent reference differs from pinned result")
        if primary_result != independent_result:
            issues.append(f"{name}: references disagree")
    return issues


if __name__ == "__main__":
    issues = workload_issues()
    if issues:
        raise ValueError("; ".join(issues))
