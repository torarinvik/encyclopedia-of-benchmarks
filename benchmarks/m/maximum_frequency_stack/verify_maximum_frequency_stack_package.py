"""Static inventory and dual-oracle fixture checker for this package."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
BENCHMARKS = PACKAGE.parents[1]
ROOT = PACKAGE.parents[2]
ALGORITHM = "maximum_frequency_stack"
SOURCE_URL = "https://leetcode.com/tag/stack/"
PORTS = (
    "c/m/maximum_frequency_stack.c",
    "c3/m/maximum_frequency_stack.c3",
    "cpp/m/maximum_frequency_stack.cpp",
    "elisa/m/maximum_frequency_stack.elisa",
    "mojo/m/maximum_frequency_stack.mojo",
    "nim/m/maximum_frequency_stack.nim",
    "odin/m/maximum_frequency_stack.odin",
    "rust/m/maximum_frequency_stack.rs",
    "v/m/maximum_frequency_stack.v",
    "zig/m/maximum_frequency_stack.zig",
)
CASE_IDS = {
    "one-push-one-pop",
    "frequency-outranks-recency",
    "latest-insertion-breaks-frequency-tie",
    "repeated-value-pushes-and-pops",
    "maximum-operation-and-output-bound",
    "signed-domain-values",
    "empty-trace-null-output-accepted",
    "zero-pop-trace-null-output-accepted",
    "empty-pop-is-invalid",
    "pop-argument-must-be-zero",
    "unknown-opcode-is-invalid",
    "push-value-out-of-range",
    "trailing-input-word-is-invalid",
    "undersized-output-for-two-pops",
    "null-output-with-pop-result",
    "null-input",
}


def _load_oracle(filename: str):
    path = BENCHMARKS / filename
    spec = importlib.util.spec_from_file_location(path.stem, path)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load oracle module: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def validate_package() -> None:
    primary = _load_oracle("maximum_frequency_stack_oracle.py")
    independent = _load_oracle("maximum_frequency_stack_naive_oracle.py")
    for oracle in (primary, independent):
        bounds = (
            oracle.MAX_OPERATIONS,
            oracle.MIN_VALUE,
            oracle.MAX_VALUE,
            oracle.MAX_VALID_INPUT_LENGTH,
            oracle.MAX_PARSEABLE_INPUT_LENGTH,
            oracle.MAX_OUTPUT_BYTES,
        )
        if bounds != (64, -8, 8, 129, 130, 256):
            raise ValueError("oracle bounds differ from the package contract")

    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    source = workload.get("source", {})
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (
        workload.get("algorithm") != ALGORITHM
        or workload.get("function_symbol") != ALGORITHM
        or workload.get("abi") != "i64_array_bytes_output"
        or source.get("url") != SOURCE_URL
        or input_spec.get("operation_count_range") != [0, 64]
        or input_spec.get("value_range") != [-8, 8]
        or input_spec.get("maximum_valid_input_length") != 129
        or input_spec.get("maximum_parseable_input_length") != 130
        or output_spec.get("maximum_bytes") != 256
        or output_spec.get("success_result") != "number of output bytes written; 8 bytes per pop"
        or "accepted when no result bytes are required" not in output_spec.get("null_output_result", "")
        or workload.get("workspace", {}).get("bytes") != 256
        or workload.get("measurement", {}).get("comparison_model") != "i64_array_bytes_output_call"
    ):
        raise ValueError("workload metadata differs from the bounded ABI contract")

    cases = workload.get("cases")
    if (
        not isinstance(cases, list)
        or len(cases) != len(CASE_IDS)
        or {case.get("id") for case in cases if isinstance(case, dict)} != CASE_IDS
    ):
        raise ValueError("workload fixtures are missing or have duplicate identifiers")
    allowed_fields = {
        "id", "input_values", "input_length", "output_capacity", "input_is_null",
        "output_is_null", "expected_result", "expected_output_bytes",
    }
    required_fields = {
        "id", "input_values", "input_length", "output_capacity",
        "expected_result", "expected_output_bytes",
    }
    for case in cases:
        if not isinstance(case, dict) or set(case) - allowed_fields or not required_fields.issubset(case):
            raise ValueError("fixture fields differ from the byte-output contract")
        values = case["input_values"]
        if (
            not isinstance(values, list)
            or type(case["input_length"]) is not int
            or case["input_length"] != len(values)
            or len(values) > primary.MAX_PARSEABLE_INPUT_LENGTH
            or not isinstance(case["expected_output_bytes"], list)
            or any(type(byte) is not int or not 0 <= byte <= 255 for byte in case["expected_output_bytes"])
        ):
            raise ValueError(f"fixture framing is invalid: {case['id']}")
        options = {
            "output_capacity": case["output_capacity"],
            "input_is_null": case.get("input_is_null", False),
            "output_is_null": case.get("output_is_null", False),
            "input_length": case["input_length"],
        }
        expected = (case["expected_result"], bytes(case["expected_output_bytes"]))
        for oracle in (primary, independent):
            if oracle.expected_output(tuple(values), **options) != expected:
                raise ValueError(f"fixture differs from an oracle: {case['id']}")

    zero_null = next(case for case in cases if case["id"] == "zero-pop-trace-null-output-accepted")
    if zero_null["expected_result"] != 0 or zero_null["expected_output_bytes"]:
        raise ValueError("zero-output null-buffer behavior is not explicitly represented")
    maximum_case = next(case for case in cases if case["id"] == "maximum-operation-and-output-bound")
    if maximum_case["input_length"] != 129 or maximum_case["expected_result"] != 256 or len(maximum_case["expected_output_bytes"]) != 256:
        raise ValueError("maximum input/output workload case is missing its declared bounds")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if SOURCE_URL not in readme or SOURCE_URL not in rights:
        raise ValueError("provenance is missing the public title-index URL")
    for phrase in ("8 bytes per pop", "accepted when the trace produces no pop results", "No individual problem page"):
        if phrase not in readme + rights:
            raise ValueError(f"docs are missing contract/provenance detail: {phrase}")
    for relative in PORTS:
        source_path = ROOT / relative
        if not source_path.is_file() or ALGORITHM not in source_path.read_text(encoding="utf-8"):
            raise ValueError(f"port is absent or lacks the exported symbol: {relative}")
        if relative not in readme:
            raise ValueError(f"README is missing a port reference: {relative}")


if __name__ == "__main__":
    validate_package()
