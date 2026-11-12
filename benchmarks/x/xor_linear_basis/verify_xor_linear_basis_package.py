"""Static workload, oracle, exhaustive-certificate, and port checks."""

from __future__ import annotations

import json
import sys
from pathlib import Path

BENCHMARKS = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(BENCHMARKS))

from xor_linear_basis_oracle import (
    MAX_INSERTIONS,
    MAX_OPERATIONS,
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    MAX_VALUE,
    expected_output as incremental_subset_oracle,
)
from xor_linear_basis_checker import expected_output as subset_mask_checker


ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks" / "x" / "xor_linear_basis"
ALGORITHM = "xor_linear_basis"
SOURCE_URL = "https://www.timothywang.ca/OI-wiki/math/linear-algebra/basis/"
LICENSE_URL = "https://github.com/OI-wiki/i18n"
PORTS = (
    "c/x/xor_linear_basis.c",
    "c3/x/xor_linear_basis.c3",
    "cpp/x/xor_linear_basis.cpp",
    "elisa/x/xor_linear_basis.elisa",
    "mojo/x/xor_linear_basis.mojo",
    "nim/x/xor_linear_basis.nim",
    "odin/x/xor_linear_basis.odin",
    "rust/x/xor_linear_basis.rs",
    "v/x/xor_linear_basis.v",
    "zig/x/xor_linear_basis.zig",
)
CASE_IDS = {
    "basic-maximum-and-membership",
    "zero-and-duplicate-insertion",
    "empty-basis-includes-empty-subset",
    "dependent-insertion-does-not-change-span",
    "highest-supported-bit",
    "sequence-without-queries",
    "invalid-operation-kind",
    "negative-query-value",
    "truncated-insert-record",
    "trailing-word-is-invalid",
    "insertion-limit-is-enforced",
    "operation-limit-is-enforced",
    "short-output-buffer",
    "null-output-buffer",
}


def validate_package() -> None:
    if (MAX_OPERATIONS, MAX_INSERTIONS, MAX_VALUE,
            MAX_VALID_INPUT_LENGTH, MAX_PARSEABLE_INPUT_LENGTH,
            MAX_OUTPUT_BYTES) != (64, 16, (1 << 63) - 1, 129, 130, 512):
        raise ValueError("oracle constants differ from the bounded profile")

    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    expected_source = {
        "title": "Linear Basis",
        "authors": ["OI Wiki contributors"],
        "reference": "OI Wiki description of greedy XOR-basis insertion, membership, and maximum subset XOR; implementation written clean-room",
        "url": SOURCE_URL,
        "license_note": "OI Wiki content is attributed under its stated CC BY-SA 4.0 and Star And Thank Author License terms; no source code or prose is reproduced",
        "algorithm_attribution": "Incremental highest-pivot XOR basis",
        "implementation_status": "clean-room bounded profile",
    }
    expected_input = {
        "kind": "signed_64_bit_integer_array",
        "encoding": "[Q,(0,x for insert | 1 for maximum query | 2,x for membership query)...]",
        "operation_count_range": [1, MAX_OPERATIONS],
        "value_range": [0, MAX_VALUE],
        "maximum_insertions": MAX_INSERTIONS,
        "maximum_valid_length": MAX_VALID_INPUT_LENGTH,
        "maximum_parseable_length": MAX_PARSEABLE_INPUT_LENGTH,
        "operation_semantics": {
            "0": "insert x into the accumulated multiset",
            "1": "output the maximum XOR of any subset of inserted values",
            "2": "output 1 iff x is the XOR of a subset of inserted values, else 0",
        },
        "invalid_input_result": -1,
    }
    expected_output = {
        "kind": "byte_array",
        "encoding": "one little-endian signed 64-bit word per query, in query order; maximum-XOR values or membership bits 0/1",
        "maximum_bytes": MAX_OUTPUT_BYTES,
        "success_result": "number of bytes written; zero when the sequence has no queries",
        "invalid_input_result": -1,
        "null_output_result": -2,
        "insufficient_capacity_result": -2,
        "empty_output_null_buffer_allowed": True,
        "output_untouched_on_error": True,
    }
    expected_contract = {
        "domain": "63-bit nonnegative integers; XOR is addition in the vector space over F_2",
        "empty_subset": "The empty subset is allowed, so zero is representable before any insertion and the initial maximum is zero.",
        "complexity": "O(63) per insertion or query and O(63) basis storage",
        "oracle_bound": "At most 16 insertions, allowing exhaustive enumeration of at most 2^16 subsets",
        "distinctness": "This package measures incremental basis insertion, maximum subset XOR, and membership; vector-space intersection and general GF(2) equation solving have different contracts.",
    }
    cases = workload.get("cases")
    expected_workload = {
        "schema_version": 1,
        "id": "xor-linear-basis-bounded-i64-array-bytes-output-v1",
        "algorithm": ALGORITHM,
        "function_symbol": ALGORITHM,
        "abi": "i64_array_bytes_output",
        "description": "Incremental 63-bit XOR linear basis with maximum-subset-XOR and membership queries.",
        "source": expected_source,
        "input": expected_input,
        "output": expected_output,
        "workspace": {
            "bytes": MAX_OUTPUT_BYTES,
            "meaning": "Maximum output-buffer capacity; 63 pivots and staged query results use separate bounded storage.",
        },
        "contract": expected_contract,
        "measurement": {
            "comparison_model": "i64_array_bytes_output_call",
            "sample_count": 5,
            "warmup_rounds": 1,
            "repetitions_per_sample": 100,
        },
        "cases": cases,
    }
    if workload != expected_workload:
        raise ValueError("workload metadata differs from the package contract")
    if (not isinstance(cases, list) or len(cases) != len(CASE_IDS)
            or {case.get("id") for case in cases if isinstance(case, dict)} != CASE_IDS):
        raise ValueError("workload fixtures are incomplete or have duplicate identifiers")

    for case in cases:
        if (not isinstance(case, dict)
                or set(case) - {"id", "input_values", "input_length", "output_capacity",
                                "input_is_null", "output_is_null", "expected_result",
                                "expected_output_hex"}
                or not {"id", "input_values", "input_length", "output_capacity",
                        "expected_result", "expected_output_hex"}.issubset(case)):
            raise ValueError("fixture fields differ from the byte-output contract")
        values = case["input_values"]
        if (not isinstance(values, list) or type(case["input_length"]) is not int
                or case["input_length"] != len(values)
                or len(values) > MAX_PARSEABLE_INPUT_LENGTH
                or type(case["output_capacity"]) is not int
                or not 0 <= case["output_capacity"] <= MAX_OUTPUT_BYTES):
            raise ValueError(f"fixture framing is invalid: {case['id']}")
        options = {
            "output_capacity": case["output_capacity"],
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case["input_length"],
        }
        expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
        if incremental_subset_oracle(values, **options) != expected:
            raise ValueError(f"fixture differs from incremental exhaustive oracle: {case['id']}")
        if subset_mask_checker(values, **options) != expected:
            raise ValueError(f"fixture differs from independent subset-mask checker: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    for required in (SOURCE_URL, "O(63)", "2^16", "clean-room", "membership"):
        if required not in readme:
            raise ValueError(f"README is missing required method or provenance text: {required}")
    if SOURCE_URL not in rights or LICENSE_URL not in rights or "CC BY-SA 4.0" not in rights:
        raise ValueError("rights and attribution notes are incomplete")
    for relative in PORTS:
        source = ROOT / relative
        if not source.is_file() or ALGORITHM not in source.read_text(encoding="utf-8"):
            raise ValueError(f"port is absent or lacks its exported symbol: {relative}")
        if relative not in readme:
            raise ValueError(f"README is missing a port link: {relative}")


if __name__ == "__main__":
    validate_package()
