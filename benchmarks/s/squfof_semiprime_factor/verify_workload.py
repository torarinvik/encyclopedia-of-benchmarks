"""Metadata-only fixture/reference reconciler; does not invoke native code."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent


def _load_oracle(name: str):
    path = PACKAGE / f"{name}.py"
    spec = importlib.util.spec_from_file_location(f"squfof_{name}", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def workload_issues() -> list[str]:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    primary = _load_oracle("primary_oracle")
    independent = _load_oracle("independent_oracle")
    issues: list[str] = []
    for case in workload.get("cases", []):
        kwargs = {
            "algorithm": workload["algorithm"],
            "input_is_null": case.get("input_is_null", False),
            "input_length": case["input_length"],
        }
        result_a = primary.expected_result(case["input_values"], **kwargs)
        result_b = independent.expected_result(case["input_values"], **kwargs)
        expected = case["expected_result"]
        if result_a != result_b:
            issues.append(f"{case['id']}: references disagree ({result_a} != {result_b})")
        if result_a != expected:
            issues.append(f"{case['id']}: pinned result {expected} differs from references ({result_a})")
    return issues


if __name__ == "__main__":
    for issue in workload_issues():
        print(issue)
    if not workload_issues():
        print("SQUFOF workload fixtures reconcile with both references")
