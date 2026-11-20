"""Reconcile the hand-pinned tuple frames with two references."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
from types import ModuleType


PACKAGE = Path(__file__).resolve().parent


def _load(name: str, path: Path) -> ModuleType:
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load reference module: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def verify_workload() -> None:
    primary = _load("multicombination_primary", PACKAGE / "primary_oracle.py")
    independent = _load("multicombination_independent", PACKAGE / "independent_oracle.py")
    workload = json.loads((PACKAGE / "workload.json").read_text())
    for case in workload["cases"]:
        args = {
            "capacity": case["output_capacity"],
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case["input_length"],
        }
        expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
        primary_result = primary.expected_output(case["input_values"], **args)
        independent_result = independent.expected_output(case["input_values"], **args)
        if primary_result != independent_result or primary_result != expected:
            raise AssertionError(
                f"{case['id']}: primary={primary_result!r}, "
                f"independent={independent_result!r}, pinned={expected!r}"
            )
