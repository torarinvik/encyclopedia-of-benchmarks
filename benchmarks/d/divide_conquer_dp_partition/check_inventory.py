"""Static inventory and fixture review for divide-and-conquer partition DP."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
from types import ModuleType

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "divide_conquer_dp_partition"
PORTS = {
    "C": ROOT / "c/d/divide_conquer_dp_partition.c",
    "C3": ROOT / "c3/d/divide_conquer_dp_partition.c3",
    "C++": ROOT / "cpp/d/divide_conquer_dp_partition.cpp",
    "Elisa": ROOT / "elisa/d/divide_conquer_dp_partition.elisa",
    "Mojo": ROOT / "mojo/d/divide_conquer_dp_partition.mojo",
    "Nim": ROOT / "nim/d/divide_conquer_dp_partition.nim",
    "Odin": ROOT / "odin/d/divide_conquer_dp_partition.odin",
    "Rust": ROOT / "rust/d/divide_conquer_dp_partition.rs",
    "V": ROOT / "v/d/divide_conquer_dp_partition.v",
    "Zig": ROOT / "zig/d/divide_conquer_dp_partition.zig",
}
EXPECTED_CASES = {
    "single-item", "one-group", "one-group-per-item", "two-groups-three-values",
    "equal-values-leftmost-tie", "zero-values-tied-splits", "interspersed-zero-values",
    "maximum-size-equal-values", "zero-items-invalid", "groups-exceed-items",
    "groups-exceed-bound", "truncated-values", "trailing-value", "negative-value",
    "value-above-bound", "null-input",
}


def _load_oracle(name: str) -> ModuleType:
    spec = importlib.util.spec_from_file_location(name, PACKAGE / f"{name}.py")
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load {name}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def check_inventory() -> list[str]:
    errors: list[str] = []
    required = ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                "independent_oracle.py", "check_inventory.py")
    for name in required:
        if not (PACKAGE / name).is_file():
            errors.append(f"missing package file: {name}")
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return errors + [f"invalid workload JSON: {error}"]
    primary = _load_oracle("primary_oracle")
    independent = _load_oracle("independent_oracle")
    if (workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"):
        errors.append("workload identity or ABI does not match the package")
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (input_spec.get("n_range") != [1, primary.MAX_N]
            or input_spec.get("group_count_range") != [1, primary.MAX_GROUPS]
            or input_spec.get("maximum_valid_length") != primary.MAX_N + 2
            or input_spec.get("maximum_parseable_length") != primary.MAX_N + 3
            or output_spec.get("valid_result_range") != [0, (primary.MAX_N * primary.MAX_VALUE) ** 2]):
        errors.append("workload bounds differ from the primary oracle")

    cases = workload.get("cases")
    if not isinstance(cases, list):
        return errors + ["workload cases must be a list"]
    case_ids = {case.get("id") for case in cases if isinstance(case, dict)}
    if len(case_ids) != len(cases) or case_ids != EXPECTED_CASES:
        errors.append("fixture IDs are duplicated or differ from the reviewed inventory")
    for case in cases:
        if not isinstance(case, dict):
            continue
        case_id = case.get("id", "<unnamed>")
        values = case.get("input_values")
        length = case.get("input_length")
        if not isinstance(values, list) or (not case.get("input_is_null", False) and length != len(values)):
            errors.append(f"input frame length mismatch: {case_id}")
            continue
        arguments = {"input_is_null": case.get("input_is_null", False), "input_length": length}
        expected = case.get("expected_result")
        if primary.expected_result(values, **arguments) != expected:
            errors.append(f"primary fixture result mismatch: {case_id}")
        if independent.expected_result(values, **arguments) != expected:
            errors.append(f"independent fixture result mismatch: {case_id}")

    for language, path in PORTS.items():
        if not path.is_file():
            errors.append(f"missing {language} port: {path.relative_to(ROOT)}")
            continue
        source = path.read_text(encoding="utf-8")
        if SYMBOL not in source:
            errors.append(f"exported symbol text missing from {path.relative_to(ROOT)}")
        if f"](../../../{path.relative_to(ROOT).as_posix()})" not in (PACKAGE / "README.md").read_text(encoding="utf-8"):
            errors.append(f"README source link missing for {language}")
    elisa = PORTS["Elisa"].read_text(encoding="utf-8")
    if "view[i64]" not in elisa or "UnsafePointer" in elisa or "ptr " in elisa:
        errors.append("Elisa implementation should use safe input views without raw pointer helpers")
    for document in ("README.md", "RIGHTS.md"):
        text = (PACKAGE / document).read_text(encoding="utf-8")
        if "https://en.oi-wiki.org/dp/opt/quadrangle/" not in text:
            errors.append(f"OI Wiki provenance is missing from {document}")
    return errors


if __name__ == "__main__":
    failures = check_inventory()
    if failures:
        raise SystemExit("\n".join(failures))
