"""Static package, workload, and port-inventory review for palindrome pairs."""

from __future__ import annotations

import json
import importlib.util
from pathlib import Path
from types import ModuleType

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/p/palindrome_pairs"


def _load_oracle(name: str, path: Path) -> ModuleType:
    spec = importlib.util.spec_from_file_location(f"_palindrome_pairs_{name}", path)
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load oracle module at {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_primary = _load_oracle("primary", PACKAGE / "primary_oracle.py")
_independent = _load_oracle("independent", PACKAGE / "independent_oracle.py")
MAX_OUTPUT_BYTES = _primary.MAX_OUTPUT_BYTES
MAX_PARSEABLE_INPUT_LENGTH = _primary.MAX_PARSEABLE_INPUT_LENGTH
MAX_VALID_INPUT_LENGTH = _primary.MAX_VALID_INPUT_LENGTH
MAX_WORDS = _primary.MAX_WORDS
WORKSPACE_BYTES = _primary.WORKSPACE_BYTES
VERIFY_MAX_PARSEABLE = _independent.MAX_PARSEABLE_INPUT_LENGTH
VERIFY_MAX_VALID = _independent.MAX_VALID_INPUT_LENGTH
primary_result = _primary.expected_output
independent_result = _independent.expected_output

SYMBOL = "palindrome_pairs"
PORTS = {
    "C": ROOT / "c/p/palindrome_pairs.c",
    "C3": ROOT / "c3/p/palindrome_pairs.c3",
    "C++": ROOT / "cpp/p/palindrome_pairs.cpp",
    "Elisa": ROOT / "elisa/p/palindrome_pairs.elisa",
    "Mojo": ROOT / "mojo/p/palindrome_pairs.mojo",
    "Nim": ROOT / "nim/p/palindrome_pairs.nim",
    "Odin": ROOT / "odin/p/palindrome_pairs.odin",
    "Rust": ROOT / "rust/p/palindrome_pairs.rs",
    "V": ROOT / "v/p/palindrome_pairs.v",
    "Zig": ROOT / "zig/p/palindrome_pairs.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    if workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL:
        issues.append("workload algorithm or exported symbol differs")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("workload ABI must be i64_array_bytes_output")
    inputs = workload.get("input", {})
    if inputs.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH:
        issues.append("maximum valid input length differs from the primary oracle")
    if inputs.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH:
        issues.append("maximum parseable input length differs from the primary oracle")
    if (VERIFY_MAX_VALID, VERIFY_MAX_PARSEABLE) != (MAX_VALID_INPUT_LENGTH, MAX_PARSEABLE_INPUT_LENGTH):
        issues.append("primary and independent input bounds differ")
    if (inputs.get("word_count_range") != [0, MAX_WORDS]
            or inputs.get("word_length_range") != [0, 8]
            or inputs.get("symbol_range") != [0, 3]):
        issues.append("word count or word length bounds differ")
    contract = workload.get("contract", {})
    output_spec = workload.get("output", {})
    if (contract.get("empty_words") != "Empty words are valid and participate in ordered pairs."
            or contract.get("output_order") != "Lexicographic order by (left_index,right_index)."):
        issues.append("empty-word or output-order semantics differ")
    if (output_spec.get("encoding") != "One byte per pair: (left_index << 3) | right_index."
            or output_spec.get("maximum_output_bytes") != MAX_OUTPUT_BYTES):
        issues.append("maximum output differs from the primary oracle")
    if workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES:
        issues.append("workspace differs from the primary oracle")

    cases = workload.get("cases", [])
    abi_cases = workload.get("abi_cases", [])
    if not isinstance(cases, list) or not isinstance(abi_cases, list):
        return issues + ["workload cases and abi_cases must be arrays"]
    all_cases = [(case, False) for case in cases] + [(case, True) for case in abi_cases]
    found_maximum = False
    found_parseable = False
    for case, is_abi in all_cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        case_id = case.get("id", "<unnamed>")
        values = case.get("input_values", [])
        if not case.get("input_is_null", False) and case.get("input_length") != len(values):
            issues.append(f"{case_id}: input length differs from its values")
        if case_id == "maximum-input-and-output":
            found_maximum = (len(values) == MAX_VALID_INPUT_LENGTH
                             and case.get("expected_result") == MAX_OUTPUT_BYTES)
        if case_id == "maximum-parseable-trailing-word":
            found_parseable = (len(values) == MAX_PARSEABLE_INPUT_LENGTH
                               and case.get("expected_result") == -1)
        try:
            payload = bytes.fromhex(case.get("expected_output_hex", ""))
        except (TypeError, ValueError):
            issues.append(f"{case_id}: expected output is not hexadecimal")
            continue
        result = case.get("expected_result")
        if isinstance(result, int) and result >= 0 and len(payload) != result:
            issues.append(f"{case_id}: result differs from expected byte count")
        if any(code > 0x3f for code in payload):
            issues.append(f"{case_id}: packed pair byte exceeds index encoding")
        if any((code >> 3) == (code & 7) for code in payload):
            issues.append(f"{case_id}: self-pair appears in output")
        if list(payload) != sorted(payload):
            issues.append(f"{case_id}: pair bytes are not in lexicographic order")
        capacity = case.get("output_capacity")
        output_is_null = case.get("output_is_null", False)
        primary = primary_result(values, capacity=capacity, output_is_null=output_is_null,
                                 input_is_null=case.get("input_is_null", False),
                                 input_length=case.get("input_length"))
        independent = independent_result(values, capacity=capacity, output_is_null=output_is_null,
                                         input_is_null=case.get("input_is_null", False),
                                         input_length=case.get("input_length"))
        if primary != (result, payload):
            issues.append(f"{case_id}: primary oracle differs from fixture")
        if independent != (result, payload):
            issues.append(f"{case_id}: independent oracle differs from fixture")
    if not found_maximum:
        issues.append("missing maximum valid input/output fixture")
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
        if "view[i64]" not in source or "mutable view[u8]" not in source:
            issues.append("Elisa must use safe views internally")
        if "input: i64&" not in source:
            issues.append("Elisa must use a ref only at the exported ABI")
        if "UnsafePointer" in source or "ptr " in source:
            issues.append("Elisa must not add raw-pointer helpers")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
