"""Static package and dual-oracle checks; this never launches benchmark ports."""

from __future__ import annotations

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
from knuth_big_integer_division_oracle import expected_output as independent_expected_output  # noqa: E402
from k.knuth_big_integer_division.primary_oracle import (  # noqa: E402
    MAX_DIGITS,
    MAX_INPUT,
    MAX_OUTPUT,
    expected_output as primary_expected_output,
)

PORTS = {
    "c": ROOT / "c/k/knuth_big_integer_division.c",
    "c3": ROOT / "c3/k/knuth_big_integer_division.c3",
    "cpp": ROOT / "cpp/k/knuth_big_integer_division.cpp",
    "elisa": ROOT / "elisa/k/knuth_big_integer_division.elisa",
    "mojo": ROOT / "mojo/k/knuth_big_integer_division.mojo",
    "nim": ROOT / "nim/k/knuth_big_integer_division.nim",
    "odin": ROOT / "odin/k/knuth_big_integer_division.odin",
    "rust": ROOT / "rust/k/knuth_big_integer_division.rs",
    "v": ROOT / "v/k/knuth_big_integer_division.v",
    "zig": ROOT / "zig/k/knuth_big_integer_division.zig",
}
TASK_URL = (
    "https://github.com/yosupo06/library-checker-problems/blob/master/"
    "big_integer/division_of_big_integers/task.md"
)


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "knuth_big_integer_division"
            or workload.get("function_symbol") != "knuth_big_integer_division"
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("source", {}).get("task_url") != TASK_URL
            or workload.get("source", {}).get("repository_license") != "Apache-2.0"
            or workload.get("measurement", {}).get("comparison_model")
                != "i64_array_bytes_output_call"):
        raise ValueError("workload identity, ABI, or source attribution is incomplete")
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (MAX_DIGITS != 64 or MAX_INPUT != 130 or MAX_OUTPUT != 129
            or input_spec.get("kind") != "signed_i64_array"
            or input_spec.get("layout")
                != "[len_a, len_b, ASCII decimal bytes for a, ASCII decimal bytes for b]"
            or input_spec.get("digit_length_range") != [1, MAX_DIGITS]
            or input_spec.get("operand_format")
                != "canonical unsigned ASCII decimal; dividend may be zero and divisor must be positive"
            or input_spec.get("maximum_valid_length") != MAX_INPUT
            or input_spec.get("maximum_parseable_length") != MAX_INPUT
            or output_spec.get("kind") != "byte_array"
            or output_spec.get("maximum_output_bytes") != MAX_OUTPUT
            or output_spec.get("invalid_input_result") != -1
            or output_spec.get("null_output_result") != -2
            or output_spec.get("insufficient_output_capacity_result") != -2
            or workload.get("contract", {}).get("limb_base") != 1_000_000_000
            or workload.get("workspace", {}).get("bytes") != 521
            or workload.get("workspace", {}).get("c_layout_bytes") != 521):
        raise ValueError("workload bounds differ from the Algorithm D profile")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if (TASK_URL not in readme or "Algorithm D" not in readme
            or "clean-room" not in readme
            or "No problem statement prose" not in rights):
        raise ValueError("README or rights note omits provenance or clean-room status")
    if len(PORTS) != 10:
        raise ValueError("the static inventory must list all ten supported languages")
    for language, path in PORTS.items():
        relative = path.relative_to(ROOT).as_posix()
        if not path.is_file():
            raise ValueError(f"missing {language} port: {relative}")
        source = path.read_text(encoding="utf-8")
        if "knuth_big_integer_division" not in source or relative not in readme:
            raise ValueError(f"port symbol or README link missing: {relative}")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain named fixtures")
    required = {
        "zero-dividend", "divisor-larger-than-dividend", "single-limb-exact-division",
        "normalized-multi-limb-quotient", "quotient-estimate-correction",
        "quotient-estimate-add-back", "malformed-leading-zero", "malformed-zero-divisor",
        "malformed-nondigit", "packed-length-mismatch", "insufficient-output-capacity", "null-output-buffer",
        "null-input-pointer",
    }
    found: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            raise ValueError("fixture must have a string ID")
        case_id = case["id"]
        if case_id in found:
            raise ValueError(f"duplicate fixture ID: {case_id}")
        found.add(case_id)
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            raise ValueError(f"fixture length mismatch: {case_id}")
        options = {
            "input_length": case.get("input_length"),
            "input_is_null": case.get("input_is_null", False),
            "output_capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
        }
        primary_status, primary_bytes = primary_expected_output(values, **options)
        independent_status, independent_bytes = independent_expected_output(values, **options)
        if (primary_status != independent_status
                or primary_status != case.get("expected_result")
                or primary_bytes != independent_bytes
                or primary_bytes.hex() != case.get("expected_output_hex")):
            raise ValueError(f"fixture differs between references: {case_id}")
        if primary_status >= 0 and primary_status != len(primary_bytes):
            raise ValueError(f"successful output length mismatch: {case_id}")
        if primary_status < 0 and primary_bytes:
            raise ValueError(f"error fixture must have empty output: {case_id}")
    if not required.issubset(found):
        raise ValueError(f"missing fixtures: {sorted(required - found)}")
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            raise ValueError(f"package documentation is missing: {name}")
    return len(cases)
