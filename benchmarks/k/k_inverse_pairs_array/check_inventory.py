"""Static workload and source-inventory review for the scalar package."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/k/k_inverse_pairs_array"
SYMBOL = "k_inverse_pairs_array"


def _load(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load oracle source: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_PRIMARY = _load("k_inverse_pairs_array_primary", ROOT / "benchmarks/k_inverse_pairs_array_oracle.py")
_INDEPENDENT = _load("k_inverse_pairs_array_independent", ROOT / "benchmarks/k_inverse_pairs_array_independent_oracle.py")
PORTS = {
    "C": ROOT / "c/k/k_inverse_pairs_array.c",
    "C3": ROOT / "c3/k/k_inverse_pairs_array.c3",
    "C++": ROOT / "cpp/k/k_inverse_pairs_array.cpp",
    "Elisa": ROOT / "elisa/k/k_inverse_pairs_array.elisa",
    "Mojo": ROOT / "mojo/k/k_inverse_pairs_array.mojo",
    "Nim": ROOT / "nim/k/k_inverse_pairs_array.nim",
    "Odin": ROOT / "odin/k/k_inverse_pairs_array.odin",
    "Rust": ROOT / "rust/k/k_inverse_pairs_array.rs",
    "V": ROOT / "v/k/k_inverse_pairs_array.v",
    "Zig": ROOT / "zig/k/k_inverse_pairs_array.zig",
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
    if (inputs.get("n_range") != [0, _PRIMARY.MAX_N]
            or inputs.get("k_range") != [0, _PRIMARY.MAX_K]
            or inputs.get("maximum_valid_length") != _PRIMARY.MAX_VALID_INPUT_LENGTH
            or inputs.get("maximum_parseable_length") != _PRIMARY.MAX_PARSEABLE_INPUT_LENGTH):
        issues.append("workload input bounds differ from the primary oracle")
    if (_INDEPENDENT.MAX_N, _INDEPENDENT.MAX_K, _INDEPENDENT.MODULUS,
            _INDEPENDENT.MAX_VALID_INPUT_LENGTH, _INDEPENDENT.MAX_PARSEABLE_INPUT_LENGTH) != (
            _PRIMARY.MAX_N, _PRIMARY.MAX_K, _PRIMARY.MODULUS,
            _PRIMARY.MAX_VALID_INPUT_LENGTH, _PRIMARY.MAX_PARSEABLE_INPUT_LENGTH):
        issues.append("primary and independent oracle contracts differ")
    if workload.get("output", {}).get("modulus") != _PRIMARY.MODULUS:
        issues.append("output modulus differs from the primary oracle")

    cases = workload.get("cases", [])
    if not isinstance(cases, list):
        return issues + ["workload cases must be a list"]
    found_maximum_n = False
    found_maximum_k = False
    found_maximum_parseable = False
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        values = case.get("input_values")
        case_id = case.get("id", "<unnamed>")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"fixture input length mismatch: {case_id}")
            continue
        expected = case.get("expected_result")
        if _PRIMARY.expected_result(values) != expected:
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if _INDEPENDENT.expected_result(values) != expected:
            issues.append(f"independent oracle fixture mismatch: {case_id}")
        if len(values) == 2 and values[0] == _PRIMARY.MAX_N:
            found_maximum_n = True
        if len(values) == 2 and values[1] == _PRIMARY.MAX_K:
            found_maximum_k = True
        if case_id == "trailing-word-invalid":
            found_maximum_parseable = len(values) == _PRIMARY.MAX_PARSEABLE_INPUT_LENGTH and expected == -1
        enumerated = _INDEPENDENT.enumerate_small(values) if len(values) == 2 and values[0] <= 9 else None
        if enumerated is not None and enumerated != expected:
            issues.append(f"factorial oracle fixture mismatch: {case_id}")
    if not found_maximum_n:
        issues.append("missing a maximum-n valid fixture")
    if not found_maximum_k:
        issues.append("missing a maximum-k valid fixture")
    if not found_maximum_parseable:
        issues.append("missing maximum-parseable trailing-word fixture")

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
