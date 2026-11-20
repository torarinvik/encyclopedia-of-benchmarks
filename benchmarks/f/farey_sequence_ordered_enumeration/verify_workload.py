"""Static fixture/oracle reconciliation; this file is not invoked here."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import (
        MAX_INPUT_LENGTH,
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
        WORKSPACE_BYTES,
        expected_output as independent_output,
    )
    from .primary_oracle import expected_output as primary_output
except ImportError:
    from independent_oracle import (
        MAX_INPUT_LENGTH,
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
        WORKSPACE_BYTES,
        expected_output as independent_output,
    )
    from primary_oracle import expected_output as primary_output

PACKAGE = Path(__file__).resolve().parent
SYMBOL = "farey_sequence_ordered_enumeration"
TASK_URL = "https://rosettagit.org/tasks/farey-sequence/"
MATH_URL = "https://mathworld.wolfram.com/FareySequence.html"
INDEPENDENT_URL = "https://people.csail.mit.edu/mip/papers/farey/farey.pdf"
CARDINALITY_URL = "https://oeis.org/A005728"
REQUIRED_CASES = {
    "independent-order-12",
    "maximum-order-32",
    "maximum-order-short-output",
    "null-output",
    "order-zero",
    "order-above-bound",
    "negative-order",
    "empty-frame",
    "trailing-word",
    "null-input",
}


def _oracle_result(case: dict, oracle) -> tuple[int, bytes]:
    return oracle(
        case.get("input_values"),
        case.get("output_capacity"),
        case.get("output_is_null", False),
        case.get("input_is_null", False),
        case.get("input_length"),
    )


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (
        workload.get("schema_version") != 1
        or workload.get("algorithm") != SYMBOL
        or workload.get("function_symbol") != SYMBOL
        or workload.get("abi") != "i64_array_bytes_output"
        or workload.get("source", {}).get("url") != TASK_URL
        or workload.get("source", {}).get("algorithm_description_url") != MATH_URL
        or workload.get("source", {}).get("independent_method_url") != INDEPENDENT_URL
        or workload.get("source", {}).get("cardinality_reference_url") != CARDINALITY_URL
        or workload.get("input", {}).get("maximum_input_length") != MAX_INPUT_LENGTH
        or workload.get("input", {}).get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
        or workload.get("output", {}).get("maximum_output_bytes") != MAX_OUTPUT_BYTES
        or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES
    ):
        raise ValueError("workload identity, bounds, or provenance differs")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain named fixtures")
    identifiers: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            raise ValueError("fixture entries require string IDs")
        case_id = case["id"]
        if case_id in identifiers:
            raise ValueError(f"duplicate fixture ID: {case_id}")
        identifiers.add(case_id)
        primary = _oracle_result(case, primary_output)
        independent = _oracle_result(case, independent_output)
        if primary != independent:
            raise ValueError(f"reference disagreement: {case_id}")
        if case.get("oracle_derived_output") is True:
            if primary[0] < 0 or primary[0] != case.get("expected_result") or len(primary[1]) != primary[0]:
                raise ValueError(f"oracle-derived fixture result differs: {case_id}")
        else:
            try:
                expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
            except (KeyError, TypeError, ValueError) as error:
                raise ValueError(f"fixture output encoding is malformed: {case_id}") from error
            if primary != expected:
                raise ValueError(f"pinned fixture differs from references: {case_id}")
    if not REQUIRED_CASES.issubset(identifiers):
        raise ValueError(f"missing fixture IDs: {sorted(REQUIRED_CASES - identifiers)}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if any(url not in readme or url not in rights for url in (TASK_URL, MATH_URL, INDEPENDENT_URL)):
        raise ValueError("README or rights note omits algorithm provenance")
    if "clean-room" not in rights or "independent" not in readme or "successor" not in readme:
        raise ValueError("README or rights note omits method distinction")
    return len(cases)


if __name__ == "__main__":
    print(f"statically reconciled {verify_workload()} workload cases")
