"""Static package metadata, fixture, oracle, and port validator; not run."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import expected_result as independent_result
    from .primary_oracle import expected_result as primary_result
except ImportError:
    from independent_oracle import expected_result as independent_result
    from primary_oracle import expected_result as primary_result

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
DISCOVERY_INDEX = "https://www.codewars.com/kata?tags=Algorithms%2CNumber+Theory"
PAPER_URL = "https://dresden.academic.wlu.edu/files/2017/08/lnzd2.pdf"
OEIS_URL = "https://oeis.org/A008904"
MAX_N = (1 << 63) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1

PORTS = {
    "c": "c/f/factorial_last_nonzero_digit.c",
    "c3": "c3/f/factorial_last_nonzero_digit.c3",
    "cpp": "cpp/f/factorial_last_nonzero_digit.cpp",
    "elisa": "elisa/f/factorial_last_nonzero_digit.elisa",
    "mojo": "mojo/f/factorial_last_nonzero_digit.mojo",
    "nim": "nim/f/factorial_last_nonzero_digit.nim",
    "odin": "odin/f/factorial_last_nonzero_digit.odin",
    "rust": "rust/f/factorial_last_nonzero_digit.rs",
    "v": "v/f/factorial_last_nonzero_digit.v",
    "zig": "zig/f/factorial_last_nonzero_digit.zig",
}

NULL_GUARDS = {
    "c": "input == NULL",
    "c3": "input == null",
    "cpp": "input == nullptr",
    "elisa": "input.is_null()",
    "mojo": "UnsafePointer[Int64, ImmutAnyOrigin]()",
    "nim": "input == nil",
    "odin": "input == nil",
    "rust": "input.is_null()",
    "v": "input == nil",
    "zig": "input_opt == null",
}

REQUIRED_CASE_RESULTS = {
    "zero-factorial": 1,
    "one-factorial": 1,
    "small-base-digit-two": 2,
    "small-base-digit-three": 6,
    "small-base-digit-four": 4,
    "first-divide-by-five-boundary": 2,
    "ten": 8,
    "twenty-five": 4,
    "one-hundred": 4,
    "one-thousand": 2,
    "power-five-twenty-seven": 8,
    "signed-64-maximum": 4,
    "negative-invalid": -1,
    "signed-64-minimum-invalid": -1,
    "empty-frame-invalid": -1,
    "trailing-word-invalid": -1,
    "too-many-words-invalid": -1,
    "null-input-invalid": -1,
}


def workload_issues(workload: dict | None = None) -> list[str]:
    """Return static package consistency issues without compiling or running ports."""
    issues: list[str] = []
    if workload is None:
        try:
            data = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    else:
        data = workload
    if not isinstance(data, dict):
        return ["workload root must be a JSON object"]

    if (data.get("schema_version") != 1
            or data.get("id") != "factorial-last-nonzero-digit-i64-array-scalar-v1"
            or data.get("algorithm") != "factorial_last_nonzero_digit"
            or data.get("function_symbol") != "factorial_last_nonzero_digit"
            or data.get("abi") != "i64_array_scalar"):
        issues.append("workload identity or ABI differs")

    source = data.get("source", {})
    if not isinstance(source, dict):
        source = {}
    if (source.get("discovery_title") != "Calculate Last Non-Zero Digit of Factorial [EX]"
            or source.get("discovery_index") != DISCOVERY_INDEX
            or source.get("url") != PAPER_URL
            or source.get("method_urls") != [PAPER_URL, OEIS_URL]
            or source.get("implementation_status") != "clean-room bounded profile"):
        issues.append("discovery or method provenance differs")
    note = source.get("discovery_note", "")
    if not isinstance(note, str) or "only" not in note.lower():
        issues.append("discovery note must state title-only use")

    input_meta = data.get("input", {})
    if not isinstance(input_meta, dict):
        input_meta = {}
    if (input_meta.get("kind") != "signed_64_bit_integer_array"
            or input_meta.get("encoding") != "[n]"
            or input_meta.get("n_range") != [0, MAX_N]
            or input_meta.get("exact_length") != 1
            or input_meta.get("maximum_valid_length") != 1
            or input_meta.get("maximum_parseable_length") != 2
            or input_meta.get("invalid_input_result") != -1
            or input_meta.get("null_input_result") != -1):
        issues.append("input contract differs")
    output_meta = data.get("output", {})
    if not isinstance(output_meta, dict):
        output_meta = {}
    if (output_meta.get("kind") != "signed_i64_scalar"
            or output_meta.get("result_range") != [0, 9]
            or output_meta.get("invalid_input_result") != -1):
        issues.append("output contract differs")
    contract = data.get("contract", {})
    if not isinstance(contract, dict):
        contract = {}
    if ("D(0..4)=(1,1,2,6,4)" not in contract.get("primary", "")
            or "D(n mod 5)" not in contract.get("primary", "")
            or "product_i(a_i!*2^(i*a_i))" not in contract.get("independent_reference", "")
            or contract.get("primary_time") != "O(log_5(n+1))"
            or contract.get("primary_space") != "O(1)"):
        issues.append("recurrence, independent method, or complexity differs")

    cases = data.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases are missing"]
    seen: set[str] = set()
    results: dict[str, int] = {}
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("fixture is not a named object")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture id: {case_id}")
            continue
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        expected = case.get("expected_result")
        if (not isinstance(values, list)
                or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                       for value in values)
                or type(length) is not int
                or type(is_null) is not bool
                or type(expected) is not int):
            issues.append(f"{case_id}: invalid fixture field types")
            continue
        if length != len(values):
            issues.append(f"{case_id}: input length does not frame its values")
        primary = primary_result(values, length, is_null)
        independent = independent_result(values, length, is_null)
        if primary != independent:
            issues.append(f"{case_id}: independent references disagree")
        if expected != primary:
            issues.append(f"{case_id}: fixture result differs from reference")
        results[case_id] = expected

    for case_id, expected in REQUIRED_CASE_RESULTS.items():
        if results.get(case_id) != expected:
            issues.append(f"required fixture missing or changed: {case_id}")

    for language, relative_path in PORTS.items():
        path = ROOT / relative_path
        if not path.is_file():
            issues.append(f"missing {language} port: {relative_path}")
            continue
        source_text = path.read_text(encoding="utf-8")
        if "factorial_last_nonzero_digit" not in source_text:
            issues.append(f"{language} port does not declare its ABI symbol")
        if NULL_GUARDS[language] not in source_text:
            issues.append(f"{language} port is missing its null-input guard")

    for name in ("README.md", "RIGHTS.md", "INVENTORY.md"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    return issues
