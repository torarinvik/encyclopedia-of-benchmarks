"""Static workload and source-inventory review for the scalar package."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/m/max_sum_rectangle_no_larger_than_k"
SYMBOL = "max_sum_rectangle_no_larger_than_k"


def _load(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load oracle source: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_PRIMARY = _load(
    "max_sum_rectangle_no_larger_than_k_primary",
    ROOT / "benchmarks/max_sum_rectangle_no_larger_than_k_oracle.py",
)
_INDEPENDENT = _load(
    "max_sum_rectangle_no_larger_than_k_independent",
    ROOT / "benchmarks/max_sum_rectangle_no_larger_than_k_independent_oracle.py",
)
PORTS = {
    "C": ROOT / "c/m/max_sum_rectangle_no_larger_than_k.c",
    "C3": ROOT / "c3/m/max_sum_rectangle_no_larger_than_k.c3",
    "C++": ROOT / "cpp/m/max_sum_rectangle_no_larger_than_k.cpp",
    "Elisa": ROOT / "elisa/m/max_sum_rectangle_no_larger_than_k.elisa",
    "Mojo": ROOT / "mojo/m/max_sum_rectangle_no_larger_than_k.mojo",
    "Nim": ROOT / "nim/m/max_sum_rectangle_no_larger_than_k.nim",
    "Odin": ROOT / "odin/m/max_sum_rectangle_no_larger_than_k.odin",
    "Rust": ROOT / "rust/m/max_sum_rectangle_no_larger_than_k.rs",
    "V": ROOT / "v/m/max_sum_rectangle_no_larger_than_k.v",
    "Zig": ROOT / "zig/m/max_sum_rectangle_no_larger_than_k.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    if workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL:
        issues.append("workload algorithm or exported symbol differs")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("workload ABI must be i64_array_scalar")
    inputs = workload.get("input", {})
    expected_bounds = {
        "rows_range": [1, _PRIMARY.MAX_ROWS],
        "columns_range": [1, _PRIMARY.MAX_COLUMNS],
        "cell_value_range": [_PRIMARY.CELL_MIN, _PRIMARY.CELL_MAX],
        "K_range": [_PRIMARY.K_MIN, _PRIMARY.K_MAX],
        "maximum_valid_length": _PRIMARY.MAX_VALID_INPUT_LENGTH,
        "maximum_parseable_length": _PRIMARY.MAX_PARSEABLE_INPUT_LENGTH,
    }
    for key, expected in expected_bounds.items():
        if inputs.get(key) != expected:
            issues.append(f"workload {key} differs from the primary oracle")
    if (
        _INDEPENDENT.MAX_ROWS,
        _INDEPENDENT.MAX_COLUMNS,
        _INDEPENDENT.CELL_MIN,
        _INDEPENDENT.CELL_MAX,
        _INDEPENDENT.K_MIN,
        _INDEPENDENT.K_MAX,
        _INDEPENDENT.MAX_VALID_INPUT_LENGTH,
        _INDEPENDENT.MAX_PARSEABLE_INPUT_LENGTH,
        _INDEPENDENT.NO_FEASIBLE_RESULT,
        _INDEPENDENT.INVALID_RESULT,
    ) != (
        _PRIMARY.MAX_ROWS,
        _PRIMARY.MAX_COLUMNS,
        _PRIMARY.CELL_MIN,
        _PRIMARY.CELL_MAX,
        _PRIMARY.K_MIN,
        _PRIMARY.K_MAX,
        _PRIMARY.MAX_VALID_INPUT_LENGTH,
        _PRIMARY.MAX_PARSEABLE_INPUT_LENGTH,
        _PRIMARY.NO_FEASIBLE_RESULT,
        _PRIMARY.INVALID_RESULT,
    ):
        issues.append("primary and independent oracle contracts differ")

    cases = workload.get("cases", [])
    if not isinstance(cases, list):
        return issues + ["workload cases must be a list"]
    found_maximum = False
    found_maximum_parseable = False
    found_null = False
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        values = case.get("input_values")
        case_id = case.get("id", "<unnamed>")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"fixture input length mismatch: {case_id}")
            continue
        if len(values) > _PRIMARY.MAX_PARSEABLE_INPUT_LENGTH:
            issues.append(f"fixture exceeds maximum parseable length: {case_id}")
            continue
        expected = case.get("expected_result")
        if _PRIMARY.expected_result(values) != expected:
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if _INDEPENDENT.expected_result(values) != expected:
            issues.append(f"independent oracle fixture mismatch: {case_id}")
        if len(values) == _PRIMARY.MAX_VALID_INPUT_LENGTH:
            found_maximum = expected != _PRIMARY.INVALID_RESULT
        if case_id == "trailing-word-invalid":
            found_maximum_parseable = (
                len(values) == _PRIMARY.MAX_PARSEABLE_INPUT_LENGTH
                and expected == _PRIMARY.INVALID_RESULT
            )
        if case.get("input_is_null") is True:
            found_null = expected == _PRIMARY.INVALID_RESULT
    if not found_maximum:
        issues.append("missing a maximum-length valid fixture")
    if not found_maximum_parseable:
        issues.append("missing a maximum-parseable trailing-word fixture")
    if not found_null:
        issues.append("missing a null-input malformed fixture")

    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"{language} port is missing its exported symbol")
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")
    elisa = PORTS["Elisa"]
    if elisa.is_file():
        source = elisa.read_text(encoding="utf-8")
        if "view[i64]" not in source or "input: i64&" not in source:
            issues.append("Elisa must use a safe view internally and refs only at its exported ABI")
        if "UnsafePointer" in source or "ptr " in source:
            issues.append("Elisa port must not introduce raw-pointer helpers")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
