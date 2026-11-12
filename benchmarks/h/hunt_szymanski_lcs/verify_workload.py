"""Static fixture, oracle, provenance, and ten-port inventory checker."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import expected_result as independent_result
    from .primary_oracle import MAX_INPUT_LENGTH, expected_result as primary_result
except ImportError:  # Direct invocation from this package directory.
    from independent_oracle import expected_result as independent_result
    from primary_oracle import MAX_INPUT_LENGTH, expected_result as primary_result

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "hunt_szymanski_lcs"
SOURCE_URL = "https://doi.org/10.1145/359581.359603"
PORTS = (
    "c/h/hunt_szymanski_lcs.c",
    "c3/h/hunt_szymanski_lcs.c3",
    "cpp/h/hunt_szymanski_lcs.cpp",
    "elisa/h/hunt_szymanski_lcs.elisa",
    "mojo/h/hunt_szymanski_lcs.mojo",
    "nim/h/hunt_szymanski_lcs.nim",
    "odin/h/hunt_szymanski_lcs.odin",
    "rust/h/hunt_szymanski_lcs.rs",
    "v/h/hunt_szymanski_lcs.v",
    "zig/h/hunt_szymanski_lcs.zig",
)


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("source", {}).get("url") != SOURCE_URL
            or workload.get("input", {}).get("maximum_valid_length") != MAX_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_input_length") != MAX_INPUT_LENGTH + 1
            or workload.get("contract", {}).get("sequence_length_range") != [0, 64]
            or workload.get("contract", {}).get("symbol_range") != [0, 127]):
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
        values = case.get("input_values")
        primary = primary_result(values)
        independent = independent_result(values)
        if primary != independent or primary != case.get("expected_result"):
            raise ValueError(f"fixture/oracle disagreement: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if (SOURCE_URL not in readme or SOURCE_URL not in rights
            or "matching pairs" not in readme
            or "clean-room" not in rights):
        raise ValueError("README or rights note omits algorithm provenance")
    if len(PORTS) != 10:
        raise ValueError("exactly ten language paths are required")
    for relative in PORTS:
        path = ROOT / relative
        if (not path.is_file() or SYMBOL not in path.read_text(encoding="utf-8")
                or relative not in readme):
            raise ValueError(f"port or README link missing: {relative}")
    return len(cases)


if __name__ == "__main__":
    print(f"statically reviewed {verify_workload()} fixtures and {len(PORTS)} ports")
