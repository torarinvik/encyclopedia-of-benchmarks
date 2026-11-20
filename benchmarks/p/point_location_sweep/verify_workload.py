"""Static fixture, Markdown-link, and language-source inventory review."""

from __future__ import annotations

import json
from pathlib import Path
import re

try:
    from .independent_oracle import expected_output as independent_output
    from .primary_oracle import (
        MAX_PARSEABLE_LENGTH, MAX_VALID_LENGTH, expected_output as primary_output,
    )
except ImportError:  # Direct invocation from the package directory.
    from independent_oracle import expected_output as independent_output
    from primary_oracle import (
        MAX_PARSEABLE_LENGTH, MAX_VALID_LENGTH, expected_output as primary_output,
    )

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "point_location_sweep"
SOURCE_URL = "https://cp-algorithms.com/geometry/point-location.html"
PORTS = (
    "c/p/point_location_sweep.c", "c3/p/point_location_sweep.c3",
    "cpp/p/point_location_sweep.cpp", "elisa/p/point_location_sweep.elisa",
    "mojo/p/point_location_sweep.mojo", "nim/p/point_location_sweep.nim",
    "odin/p/point_location_sweep.odin", "rust/p/point_location_sweep.rs",
    "v/p/point_location_sweep.v", "zig/p/point_location_sweep.zig",
)


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"):
        raise ValueError("workload identity mismatch")
    input_contract = workload.get("input", {})
    if (input_contract.get("maximum_valid_length") != MAX_VALID_LENGTH
            or input_contract.get("maximum_parseable_length") != MAX_PARSEABLE_LENGTH):
        raise ValueError("workload length bounds differ from the contract")
    if SOURCE_URL not in workload.get("source", {}).get("urls", []):
        raise ValueError("workload source attribution is incomplete")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain fixtures")
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str) or case["id"] in seen:
            raise ValueError("fixture IDs must be unique strings")
        seen.add(case["id"])
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            raise ValueError(f"fixture length mismatch: {case['id']}")
        options = {"input_is_null": case.get("input_is_null", False),
                   "input_length": case.get("input_length")}
        expected = case.get("expected_result")
        if primary_output(values, **options) != expected:
            raise ValueError(f"primary oracle/workload mismatch: {case['id']}")
        if independent_output(values, **options) != expected:
            raise ValueError(f"independent oracle/workload mismatch: {case['id']}")

    maximum = next((case for case in cases
                    if case.get("id") == "maximum-valid-active-set-frame"), None)
    if (maximum is None or maximum.get("input_length") != MAX_VALID_LENGTH
            or maximum.get("expected_result") != 0):
        raise ValueError("maximum frame is missing or has an unexpected result")
    parseable_maximum = next((case for case in cases
                              if case.get("id") == "maximum-parseable-trailing-word"), None)
    if (parseable_maximum is None
            or parseable_maximum.get("input_length") != MAX_PARSEABLE_LENGTH
            or parseable_maximum.get("expected_result") != -1
            or parseable_maximum.get("input_values") != maximum.get("input_values") + [0]):
        raise ValueError("maximum parseable rejection frame is missing")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if SOURCE_URL not in readme or SOURCE_URL not in rights:
        raise ValueError("README or RIGHTS omits the primary source")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file():
            raise ValueError(f"missing language port: {relative}")
        if SYMBOL not in path.read_text(encoding="utf-8"):
            raise ValueError(f"missing exported symbol text: {relative}")
        if relative not in readme:
            raise ValueError(f"README does not link {relative}")
    for target in re.findall(r"\[[^\]]*\]\(([^)]+)\)", readme):
        if "://" not in target and not (PACKAGE / target).resolve().is_file():
            raise ValueError(f"README target is missing: {target}")
    return len(cases)


if __name__ == "__main__":
    print(f"statically reviewed {verify_workload()} fixtures and {len(PORTS)} ports")
