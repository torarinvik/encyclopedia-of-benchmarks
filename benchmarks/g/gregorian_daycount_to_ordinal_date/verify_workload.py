"""Hand-pinned workload reconciliation helper; authoring only, not run."""

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
    primary = _load("gregorian_daycount_primary", PACKAGE / "primary_oracle.py")
    independent = _load("gregorian_daycount_independent", PACKAGE / "independent_oracle.py")
    workload = json.loads((PACKAGE / "workload.json").read_text())
    for case in workload["cases"]:
        arguments = {
            "capacity": case["output_capacity"],
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case["input_length"],
        }
        expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
        first = primary.expected_output(case["input_values"], **arguments)
        second = independent.expected_output(case["input_values"], **arguments)
        if first != second or first != expected:
            raise AssertionError(
                f"{case['id']}: primary={first!r}, independent={second!r}, pinned={expected!r}"
            )
