"""Static package inventory and fixture/oracle consistency validator.

This file is provided for repository integration. It is intentionally not run
under the active source-only constraint.
"""
from __future__ import annotations

import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SYMBOL = "min_cost_max_flow_blocking_paths"

PORTS = {
    "c/m/min_cost_max_flow_blocking_paths.c": "min_cost_max_flow_blocking_paths",
    "c3/m/min_cost_max_flow_blocking_paths.c3": "min_cost_max_flow_blocking_paths",
    "cpp/m/min_cost_max_flow_blocking_paths.cpp": "min_cost_max_flow_blocking_paths",
    "elisa/m/min_cost_max_flow_blocking_paths.elisa": "min_cost_max_flow_blocking_paths",
    "mojo/m/min_cost_max_flow_blocking_paths.mojo": "min_cost_max_flow_blocking_paths",
    "nim/m/min_cost_max_flow_blocking_paths.nim": "min_cost_max_flow_blocking_paths",
    "odin/m/min_cost_max_flow_blocking_paths.odin": "min_cost_max_flow_blocking_paths",
    "rust/m/min_cost_max_flow_blocking_paths.rs": "min_cost_max_flow_blocking_paths",
    "v/m/min_cost_max_flow_blocking_paths.v": "min_cost_max_flow_blocking_paths",
    "zig/m/min_cost_max_flow_blocking_paths.zig": "min_cost_max_flow_blocking_paths",
}


def _load_oracle(path: Path, module_name: str):
    spec = importlib.util.spec_from_file_location(module_name, path)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load oracle metadata from {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def validate_package() -> list[str]:
    errors: list[str] = []
    workload_path = PACKAGE / "workload.json"
    try:
        workload = json.loads(workload_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]

    if workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL:
        errors.append("workload algorithm and function symbol must match package symbol")
    if workload.get("workspace", {}).get("bytes", 0) < 16:
        errors.append("workload must declare at least 16 output-workspace bytes")
    contract = workload.get("contract", {})
    if contract.get("output_bytes") != 16:
        errors.append("contract output_bytes must be 16")
    if contract.get("input_layout", "").count("edge_count") == 0:
        errors.append("contract must document the edge-list input layout")

    for relative_path, symbol in PORTS.items():
        path = ROOT / relative_path
        if not path.is_file():
            errors.append(f"missing port: {relative_path}")
            continue
        try:
            source = path.read_text(encoding="utf-8")
        except OSError as error:
            errors.append(f"cannot read {relative_path}: {error}")
            continue
        if symbol not in source:
            errors.append(f"export symbol is absent from {relative_path}")
        if "Based on AtCoder Library" in source:
            errors.append(f"unexpected inherited AtCoder attribution in {relative_path}")

    for required in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / required).is_file():
            errors.append(f"missing package artifact: {required}")

    try:
        primary = _load_oracle(ROOT / "benchmarks/min_cost_max_flow_blocking_paths_oracle.py",
                               "mcmfb_primary_oracle")
        independent = _load_oracle(ROOT / "benchmarks/min_cost_max_flow_blocking_paths_independent_oracle.py",
                                   "mcmfb_independent_oracle")
    except (OSError, ValueError) as error:
        return errors + [f"cannot load package oracles: {error}"]

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        errors.append("workload cases must be a nonempty list")
        return errors
    for case in cases:
        name = case.get("id", "<unnamed>")
        values = case.get("input_values")
        capacity = case.get("output_capacity")
        expected_result = case.get("expected_result")
        expected_hex = case.get("expected_output_hex")
        if not isinstance(values, list) or not isinstance(expected_hex, str):
            errors.append(f"{name}: malformed fixture fields")
            continue
        try:
            expected_bytes = bytes.fromhex(expected_hex)
        except ValueError:
            errors.append(f"{name}: invalid output hex")
            continue
        for label, oracle in (("primary", primary), ("independent", independent)):
            result, output = oracle.expected_output(values, capacity)
            if result != expected_result or output != expected_bytes:
                errors.append(f"{name}: {label} oracle disagrees with fixture output")
    return errors


if __name__ == "__main__":
    issues = validate_package()
    if issues:
        raise SystemExit("\n".join(issues))
    print("min_cost_max_flow_blocking_paths package inventory and fixtures are consistent")
