"""Static comparison of the workload with both source references."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent


def _load(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(f"_race_car_{name}", path)
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load reference at {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def verify_workload() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"invalid workload: {error}"]
    primary = _load("primary", PACKAGE / "primary_oracle.py")
    independent = _load("independent", PACKAGE / "independent_oracle.py")
    if workload.get("algorithm") != "race_car_minimum_instruction_count":
        issues.append("unexpected algorithm name")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases must be a nonempty list"]
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("input_values"), list):
            issues.append("malformed workload record")
            continue
        arguments = (
            case["input_values"], case.get("input_is_null", False),
            case.get("input_length"),
        )
        left = primary.expected_result(*arguments)
        right = independent.expected_result(*arguments)
        if left != right:
            issues.append(f"{case.get('id', '<unnamed>')}: references disagree")
        if left != case.get("expected_result"):
            issues.append(f"{case.get('id', '<unnamed>')}: fixture differs from references")
    return issues


if __name__ == "__main__":
    raise SystemExit("\n".join(verify_workload()))
