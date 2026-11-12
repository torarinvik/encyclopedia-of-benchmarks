"""Static fixture, oracle, provenance, and ten-port inventory checker."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import expected_output as independent_output
    from .primary_oracle import (
        MAX_INPUT_LENGTH,
        MAX_OUTPUT_BYTES,
        MAX_TEXT_LENGTH,
        WORKSPACE_BYTES,
        expected_output as primary_output,
    )
except ImportError:  # Direct invocation from this package directory.
    from independent_oracle import expected_output as independent_output
    from primary_oracle import (
        MAX_INPUT_LENGTH,
        MAX_OUTPUT_BYTES,
        MAX_TEXT_LENGTH,
        WORKSPACE_BYTES,
        expected_output as primary_output,
    )

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "suffix_array_sais"
PAPER_URL = "https://doi.org/10.1109/DCC.2009.42"
OI_WIKI_URL = "https://oi-wiki.org/string/sa/"
PORTS = (
    "c/s/suffix_array_sais.c",
    "c3/s/suffix_array_sais.c3",
    "cpp/s/suffix_array_sais.cpp",
    "elisa/s/suffix_array_sais.elisa",
    "mojo/s/suffix_array_sais.mojo",
    "nim/s/suffix_array_sais.nim",
    "odin/s/suffix_array_sais.odin",
    "rust/s/suffix_array_sais.rs",
    "v/s/suffix_array_sais.v",
    "zig/s/suffix_array_sais.zig",
)


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
        or workload.get("source", {}).get("url") != PAPER_URL
        or workload.get("source", {}).get("algorithm_description_url") != OI_WIKI_URL
        or workload.get("input", {}).get("text_length_range") != [0, MAX_TEXT_LENGTH]
        or workload.get("input", {}).get("maximum_valid_length") != MAX_TEXT_LENGTH + 1
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
        primary = _oracle_result(case, primary_output)
        independent = _oracle_result(case, independent_output)
        try:
            expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
        except (KeyError, TypeError, ValueError) as error:
            raise ValueError(f"fixture output encoding is malformed: {case['id']}") from error
        if primary != independent or primary != expected:
            raise ValueError(f"fixture/oracle disagreement: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if (
        PAPER_URL not in readme
        or PAPER_URL not in rights
        or OI_WIKI_URL not in readme
        or OI_WIKI_URL not in rights
        or "clean-room" not in rights
        or "rank doubling" not in readme
        or "DC3" not in readme
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
