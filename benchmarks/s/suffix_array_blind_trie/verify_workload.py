"""Static workload, provenance, and ten-port inventory checker."""

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
except ImportError:
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
SYMBOL = "suffix_array_blind_trie"
PAPER_URL = "https://doi.org/10.1007/s00453-004-1094-1"
PAPER_PDF_URL = "https://people.unipmn.it/manzini/papers/esa02.pdf"
DADS_URL = "https://xlinux.nist.gov/dads/HTML/blindSort.html"
PORTS = (
    "c/s/suffix_array_blind_trie.c",
    "c3/s/suffix_array_blind_trie.c3",
    "cpp/s/suffix_array_blind_trie.cpp",
    "elisa/s/suffix_array_blind_trie.elisa",
    "mojo/s/suffix_array_blind_trie.mojo",
    "nim/s/suffix_array_blind_trie.nim",
    "odin/s/suffix_array_blind_trie.odin",
    "rust/s/suffix_array_blind_trie.rs",
    "v/s/suffix_array_blind_trie.v",
    "zig/s/suffix_array_blind_trie.zig",
)
REQUIRED_CASES = {
    "empty_text",
    "single_nul",
    "banana",
    "equal_symbols",
    "periodic_symbols",
    "prefix_and_terminator_order",
    "embedded_nul_and_high_byte",
    "maximum_valid_frame_short_capacity",
    "invalid_symbol",
    "trailing_input",
    "over_bound_text",
    "short_capacity",
    "null_input",
    "null_output_for_empty_text",
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
        or workload.get("source", {}).get("url") != PAPER_URL
        or workload.get("source", {}).get("algorithm_description_url") != PAPER_PDF_URL
        or workload.get("source", {}).get("discovery_url") != DADS_URL
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
    if not REQUIRED_CASES <= identifiers:
        raise ValueError(f"required fixture missing: {sorted(REQUIRED_CASES - identifiers)}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    inventory = (PACKAGE / "INVENTORY.md").read_text(encoding="utf-8")
    for source in (PAPER_URL, PAPER_PDF_URL, DADS_URL):
        if source not in readme or source not in rights:
            raise ValueError("README or rights note omits a cited source")
    if (
        "clean-room" not in rights
        or "suffix_array_dc3" not in readme
        or "suffix_array_sais" not in readme
        or "ordered blind trie" not in inventory
    ):
        raise ValueError("package distinction or clean-room inventory is incomplete")
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
