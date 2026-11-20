"""Static inventory and reference-agreement checks for the LZ78RL package."""

import json
import re
from pathlib import Path

from .independent_oracle import expected_output as independent
from .primary_oracle import (
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_TOKEN_COUNT,
    MAX_TEXT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    expected_output as primary,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
NAME = "lz78_run_length_transform"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}


def static_issues(workload=None):
    if workload is None:
        try:
            with (PACKAGE / "workload.json").open(encoding="utf-8") as stream:
                workload = json.load(stream)
        except (OSError, ValueError) as error:
            return [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]

    issues = []
    input_spec = workload.get("input")
    output_spec = workload.get("output")
    if (workload.get("schema_version") != 1
            or workload.get("id") != "encyclopedia-doi634-lz78-run-length-transform-i64-array-bytes-output-v1"
            or workload.get("algorithm") != NAME
            or workload.get("function_symbol") != NAME
            or workload.get("abi") != "i64_array_bytes_output"
            or not isinstance(input_spec, dict)
            or input_spec.get("layout") != "[n, symbol_0, ..., symbol_(n-1)]"
            or input_spec.get("text_length_range") != [0, MAX_TEXT_LENGTH]
            or input_spec.get("exact_valid_length") != "n+1"
            or input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_spec.get("symbol_code_range") != [1, 3]
            or input_spec.get("reserved_transform_symbol") != 0
            or not isinstance(workload.get("transform"), dict)
            or workload["transform"].get("encoding") !=
               "Write m in ordinary MSB-first binary with no leading zero; replace each one bit by alpha and each zero bit by reserved symbol 0."
            or not isinstance(workload.get("lz78"), dict)
            or workload["lz78"].get("terminal_token") != "(existing_phrase_id, 0, 1)"
            or not isinstance(output_spec, dict)
            or output_spec.get("encoding") != "[token_count, (parent_id, next_symbol, terminal_tag)*]"
            or output_spec.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or output_spec.get("maximum_token_count") != MAX_TOKEN_COUNT
            or output_spec.get("invalid_result") != -1
            or output_spec.get("insufficient_output_capacity_result") != -2
            or output_spec.get("null_output_result") != -2
            or output_spec.get("errors_write_nothing") is not True):
        issues.append("identity or bounds mismatch")

    source = workload.get("source")
    if (not isinstance(source, dict)
            or source.get("doi") != "10.1137/S0097539797331105"
            or source.get("chapter_url") != "https://doi.org/10.1007/978-1-4939-2864-4_634"
            or source.get("section") != "3.1, LZ78RL"
            or "clean-room" not in source.get("attribution", "")):
        issues.append("source attribution mismatch")

    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "l" / f"{NAME}.{extension}"
        if not path.is_file():
            issues.append(f"missing port: {language}")
        elif NAME not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol: {language}")

    for filename in ("README.md", "RIGHTS.md", "workload.json",
                     "primary_oracle.py", "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package artifact: {filename}")

    readme = PACKAGE / "README.md"
    if readme.is_file():
        text = readme.read_text(encoding="utf-8")
        for language, extension in EXTENSIONS.items():
            relative = f"../../../{language}/l/{NAME}.{extension}"
            if f"]({relative})" not in text:
                issues.append(f"README port target missing: {language}")
        for target in re.findall(r"\]\(([^)]+)\)", text):
            if target.startswith(("https://", "http://", "#")):
                continue
            if not (PACKAGE / target).resolve().is_file():
                issues.append(f"README local link does not resolve: {target}")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing workload cases"]
    seen = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid case record")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate case id: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        capacity = case.get("output_capacity")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        if (not isinstance(values, list)
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                       for value in values)
                or type(length) is not int
                or not 0 <= length <= MAX_PARSEABLE_INPUT_LENGTH
                or type(capacity) is not int or capacity < 0
                or type(input_is_null) is not bool
                or type(output_is_null) is not bool
                or (input_is_null and values)
                or (input_is_null and length not in (0, MAX_PARSEABLE_INPUT_LENGTH))
                or (not input_is_null and length != len(values))):
            issues.append(f"invalid framing: {case_id}")
            continue
        try:
            expected = (case["expected_result"],
                        bytes.fromhex(case["expected_output_hex"]))
        except (KeyError, TypeError, ValueError):
            issues.append(f"invalid expected output: {case_id}")
            continue
        args = (values, capacity, output_is_null, input_is_null, length)
        if (type(expected[0]) is not int
                or primary(*args) != expected
                or independent(*args) != expected):
            issues.append(f"oracle/workload disagreement: {case_id}")

    required = {
        "empty-input", "single-symbol-run", "binary-101-run-and-terminal-tag",
        "reserved-zero-as-symbol-and-terminal", "multiple-run-binary-transform",
        "alternating-singleton-runs-terminal", "maximum-repetitive-frame",
        "invalid-reserved-input-symbol",
        "invalid-symbol-above-alphabet", "invalid-trailing-word",
        "invalid-n-over-maximum",
        "short-output", "null-output", "null-input-zero-length",
        "null-input-maximum-parseable-length",
    }
    if not required <= seen:
        issues.append("missing required fixtures")
    return issues


def verify(workload=None):
    issues = static_issues(workload)
    if issues:
        raise ValueError("; ".join(issues))
    return True
