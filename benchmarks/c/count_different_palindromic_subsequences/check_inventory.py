"""Static workload and source-inventory review for the bounded scalar package."""

from __future__ import annotations

import json
import importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/c/count_different_palindromic_subsequences"
SYMBOL = "count_different_palindromic_subsequences"


def _load_oracle(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load oracle source: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_PRIMARY = _load_oracle(
    "count_different_palindromic_subsequences_primary",
    ROOT / "benchmarks/count_different_palindromic_subsequences_oracle.py",
)
_INDEPENDENT = _load_oracle(
    "count_different_palindromic_subsequences_independent",
    ROOT / "benchmarks/count_different_palindromic_subsequences_verifier_oracle.py",
)
ALPHABET_SIZE = _PRIMARY.ALPHABET_SIZE
MAX_LENGTH = _PRIMARY.MAX_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = _PRIMARY.MAX_PARSEABLE_INPUT_LENGTH
MAX_VALID_INPUT_LENGTH = _PRIMARY.MAX_VALID_INPUT_LENGTH
MODULUS = _PRIMARY.MODULUS
VERIFY_ALPHABET_SIZE = _INDEPENDENT.ALPHABET_SIZE
VERIFY_MAX_LENGTH = _INDEPENDENT.MAX_LENGTH
VERIFY_MAX_PARSEABLE_INPUT_LENGTH = _INDEPENDENT.MAX_PARSEABLE_INPUT_LENGTH
VERIFY_MAX_VALID_INPUT_LENGTH = _INDEPENDENT.MAX_VALID_INPUT_LENGTH
VERIFY_MODULUS = _INDEPENDENT.MODULUS
PORTS = {
    "C": ROOT / "c/c/count_different_palindromic_subsequences.c",
    "C3": ROOT / "c3/c/count_different_palindromic_subsequences.c3",
    "C++": ROOT / "cpp/c/count_different_palindromic_subsequences.cpp",
    "Elisa": ROOT / "elisa/c/count_different_palindromic_subsequences.elisa",
    "Mojo": ROOT / "mojo/c/count_different_palindromic_subsequences.mojo",
    "Nim": ROOT / "nim/c/count_different_palindromic_subsequences.nim",
    "Odin": ROOT / "odin/c/count_different_palindromic_subsequences.odin",
    "Rust": ROOT / "rust/c/count_different_palindromic_subsequences.rs",
    "V": ROOT / "v/c/count_different_palindromic_subsequences.v",
    "Zig": ROOT / "zig/c/count_different_palindromic_subsequences.zig",
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
    if inputs.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH:
        issues.append("maximum valid input length differs from the primary oracle")
    if inputs.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH:
        issues.append("maximum parseable input length differs from the primary oracle")
    if (VERIFY_MAX_LENGTH, VERIFY_ALPHABET_SIZE, VERIFY_MODULUS,
            VERIFY_MAX_VALID_INPUT_LENGTH, VERIFY_MAX_PARSEABLE_INPUT_LENGTH) != (
            MAX_LENGTH, ALPHABET_SIZE, MODULUS, MAX_VALID_INPUT_LENGTH, MAX_PARSEABLE_INPUT_LENGTH):
        issues.append("primary and independent oracle bounds differ")
    if inputs.get("length_range") != [0, MAX_LENGTH] or inputs.get("symbol_range") != [0, ALPHABET_SIZE - 1]:
        issues.append("input bounds differ from the bounded profile")
    if workload.get("output", {}).get("modulus") != MODULUS:
        issues.append("output modulus differs from the oracle")

    cases = workload.get("cases", [])
    if not isinstance(cases, list):
        return issues + ["workload cases must be a list"]
    found_maximum = False
    found_parseable = False
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
        if case_id == "maximum-length-repeated-symbol":
            found_maximum = len(values) == MAX_VALID_INPUT_LENGTH and values[0] == MAX_LENGTH
        if case_id == "trailing-word-invalid":
            found_parseable = len(values) == MAX_PARSEABLE_INPUT_LENGTH and expected == -1
    if not found_maximum:
        issues.append("missing maximum-valid-length fixture")
    if not found_parseable:
        issues.append("missing maximum-parseable trailing-word fixture")

    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"{language} port is missing its exported symbol")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")
    elisa_path = PORTS["Elisa"]
    if elisa_path.is_file():
        source = elisa_path.read_text(encoding="utf-8")
        if "view[i64]" not in source or "input: i64&" not in source:
            issues.append("Elisa must use safe views internally and refs only at its exported ABI")
        if "UnsafePointer" in source or "ptr " in source:
            issues.append("Elisa port must not introduce raw-pointer helpers")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
