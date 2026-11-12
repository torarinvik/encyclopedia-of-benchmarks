"""Static fixture, oracle, provenance, and ten-port inventory checker."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import expected_output as independent_output
    from .primary_oracle import (
        MAX_INPUT_LENGTH,
        MAX_OUTPUT_BYTES,
        MAX_PATTERN_LENGTH,
        MAX_TEXT_LENGTH,
        WORKSPACE_BYTES,
        expected_output as primary_output,
    )
except ImportError:  # Direct invocation from this package directory.
    from independent_oracle import expected_output as independent_output
    from primary_oracle import (
        MAX_INPUT_LENGTH,
        MAX_OUTPUT_BYTES,
        MAX_PATTERN_LENGTH,
        MAX_TEXT_LENGTH,
        WORKSPACE_BYTES,
        expected_output as primary_output,
    )

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "crochemore_perrin_two_way"
SOURCE_URL = "https://doi.org/10.1145/116825.116845"
PORTS = (
    "c/c/crochemore_perrin_two_way.c",
    "c3/c/crochemore_perrin_two_way.c3",
    "cpp/c/crochemore_perrin_two_way.cpp",
    "elisa/c/crochemore_perrin_two_way.elisa",
    "mojo/c/crochemore_perrin_two_way.mojo",
    "nim/c/crochemore_perrin_two_way.nim",
    "odin/c/crochemore_perrin_two_way.odin",
    "rust/c/crochemore_perrin_two_way.rs",
    "v/c/crochemore_perrin_two_way.v",
    "zig/c/crochemore_perrin_two_way.zig",
)


def _result(case: dict, oracle) -> tuple[int, bytes]:
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
        or workload.get("source", {}).get("url") != SOURCE_URL
        or workload.get("input", {}).get("text_length_range") != [0, MAX_TEXT_LENGTH]
        or workload.get("input", {}).get("pattern_length_range") != [0, MAX_PATTERN_LENGTH]
        or workload.get("input", {}).get("maximum_valid_length") != MAX_TEXT_LENGTH + MAX_PATTERN_LENGTH + 2
        or workload.get("input", {}).get("maximum_parseable_length") != MAX_INPUT_LENGTH
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
        if case["id"] in identifiers:
            raise ValueError(f"duplicate fixture ID: {case['id']}")
        identifiers.add(case["id"])
        primary = _result(case, primary_output)
        independent = _result(case, independent_output)
        try:
            expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
        except (KeyError, TypeError, ValueError) as error:
            raise ValueError(f"fixture output encoding is malformed: {case['id']}") from error
        if primary != independent or primary != expected:
            raise ValueError(f"fixture/oracle disagreement: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if (
        SOURCE_URL not in readme
        or SOURCE_URL not in rights
        or "critical factorization" not in readme
        or "clean-room" not in rights
        or "prefix_function" not in readme
        or "boyer_moore" not in readme
    ):
        raise ValueError("README or rights note omits provenance or distinction")
    if len(PORTS) != 10:
        raise ValueError("exactly ten language paths are required")
    for relative in PORTS:
        path = ROOT / relative
        if (
            not path.is_file()
            or SYMBOL not in path.read_text(encoding="utf-8")
            or relative not in readme
        ):
            raise ValueError(f"port or README link missing: {relative}")
    return len(cases)


if __name__ == "__main__":
    print(f"statically reviewed {verify_workload()} fixtures and {len(PORTS)} ports")
