"""Static package, workload, oracle, and ten-port inventory review."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
from types import ModuleType

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "bounded_knapsack_monotone_queue"
PORTS = {
    "C": ROOT / "c/b/bounded_knapsack_monotone_queue.c",
    "C3": ROOT / "c3/b/bounded_knapsack_monotone_queue.c3",
    "C++": ROOT / "cpp/b/bounded_knapsack_monotone_queue.cpp",
    "Elisa": ROOT / "elisa/b/bounded_knapsack_monotone_queue.elisa",
    "Mojo": ROOT / "mojo/b/bounded_knapsack_monotone_queue.mojo",
    "Nim": ROOT / "nim/b/bounded_knapsack_monotone_queue.nim",
    "Odin": ROOT / "odin/b/bounded_knapsack_monotone_queue.odin",
    "Rust": ROOT / "rust/b/bounded_knapsack_monotone_queue.rs",
    "V": ROOT / "v/b/bounded_knapsack_monotone_queue.v",
    "Zig": ROOT / "zig/b/bounded_knapsack_monotone_queue.zig",
}


def _load(name: str, path: Path) -> ModuleType:
    spec = importlib.util.spec_from_file_location(f"_bounded_knapsack_{name}", path)
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load oracle module at {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_primary = _load("primary", PACKAGE / "primary_oracle.py")
_independent = _load("independent", PACKAGE / "independent_oracle.py")


def check_inventory() -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
            continue
        if SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"{language} port does not declare {SYMBOL}")
    elisa = PORTS["Elisa"]
    if elisa.is_file():
        source = elisa.read_text(encoding="utf-8")
        if "view[i64]" not in source or "input: i64&" not in source:
            issues.append("Elisa must use a safe input view and keep its ABI reference at the entry point")
        if "UnsafePointer" in source or "ptr " in source:
            issues.append("Elisa must not use raw pointers")

    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"invalid workload JSON: {error}"]
    if workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL:
        issues.append("workload algorithm and symbol differ from the package")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("workload ABI must be i64_array_scalar")
    input_spec = workload.get("input", {})
    expected_input = {
        "encoding": "[capacity,type_count,(weight,value,count)*type_count]",
        "capacity_range": [0, 64],
        "type_count_range": [0, 16],
        "weight_range": [1, 16],
        "value_range": [0, 100],
        "multiplicity_range": [0, 16],
        "maximum_valid_length": 50,
        "maximum_parseable_input_length": 51,
        "invalid_input_result": -1,
    }
    for key, value in expected_input.items():
        if input_spec.get(key) != value:
            issues.append(f"input field {key!r} differs from the bounded contract")

    try:
        cases = workload["cases"]
    except (KeyError, TypeError):
        return issues + ["workload cases must be present"]
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases must be a nonempty list"]
    found_maximum = False
    found_trailing = False
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        case_id = case.get("id", "<unnamed>")
        values = case.get("input_values")
        if not isinstance(values, list):
            issues.append(f"{case_id}: input_values must be a list")
            continue
        declared = case.get("input_length")
        if case.get("input_is_null") is not True and declared != len(values):
            issues.append(f"{case_id}: declared input length differs from the frame")
        if case_id == "maximum-valid-frame":
            found_maximum = len(values) == 50 and declared == 50
        if case_id == "trailing-word":
            found_trailing = len(values) == 6 and case.get("expected_result") == -1
        expected = case.get("expected_result")
        if _primary.expected_result(values) != expected:
            issues.append(f"{case_id}: primary oracle differs from expected_result")
        if _independent.expected_result(values) != expected:
            issues.append(f"{case_id}: independent oracle differs from expected_result")
    if not found_maximum:
        issues.append("missing maximum 50-value frame")
    if not found_trailing:
        issues.append("missing one-word trailing-input rejection case")
    return issues


static_issues = check_inventory


if __name__ == "__main__":
    failures = check_inventory()
    if failures:
        raise SystemExit("\n".join(failures))
