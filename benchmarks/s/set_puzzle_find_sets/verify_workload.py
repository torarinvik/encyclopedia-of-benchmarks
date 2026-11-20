"""Static fixture/oracle comparison source; deliberately not executed here."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent


def _load(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(f"_set_puzzle_{name}", path)
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load oracle at {path}")
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
    if workload.get("algorithm") != "set_puzzle_find_sets":
        issues.append("unexpected algorithm name")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases must be a nonempty list"]
    for case in cases:
        name = case.get("id", "<unnamed>") if isinstance(case, dict) else "<non-object>"
        if not isinstance(case, dict) or not isinstance(case.get("input_values"), list):
            issues.append(f"{name}: malformed case")
            continue
        arguments = (
            case["input_values"], case.get("output_capacity"),
            case.get("output_is_null", False), case.get("input_is_null", False),
            case.get("input_length"),
        )
        expected = (case.get("expected_result"), bytes.fromhex(case.get("expected_output_hex", "")))
        primary_result = primary.expected_output(*arguments)
        independent_result = independent.expected_output(*arguments)
        if primary_result != expected:
            issues.append(f"{name}: primary reference disagrees with fixture")
        if independent_result != expected:
            issues.append(f"{name}: independent reference disagrees with fixture")
        if primary_result != independent_result:
            issues.append(f"{name}: references disagree")
    return issues


if __name__ == "__main__":
    raise SystemExit("\n".join(verify_workload()))
