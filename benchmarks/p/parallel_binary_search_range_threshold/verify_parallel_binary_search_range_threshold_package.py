"""Static workload, oracle, provenance, and ten-port inventory review."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SOURCE_URL = "https://en.oi-wiki.org/misc/parallel-binsearch/"
PORTS = (
    "c/p/parallel_binary_search_range_threshold.c",
    "c3/p/parallel_binary_search_range_threshold.c3",
    "cpp/p/parallel_binary_search_range_threshold.cpp",
    "elisa/p/parallel_binary_search_range_threshold.elisa",
    "mojo/p/parallel_binary_search_range_threshold.mojo",
    "nim/p/parallel_binary_search_range_threshold.nim",
    "odin/p/parallel_binary_search_range_threshold.odin",
    "rust/p/parallel_binary_search_range_threshold.rs",
    "v/p/parallel_binary_search_range_threshold.v",
    "zig/p/parallel_binary_search_range_threshold.zig",
)


def _load(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load oracle source: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def verify_workload() -> int:
    primary = _load("pbs_threshold_primary", PACKAGE / "primary_oracle.py")
    independent = _load("pbs_threshold_independent", PACKAGE / "independent_oracle.py")
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    contract = workload.get("input", {})
    output = workload.get("output", {})
    expected_input = {
        "kind": "signed_64_bit_integer_array",
        "encoding": "[N,M,Q,(L,R,delta)*M,(L,R,target)*Q]",
        "array_length_range": [1, 16],
        "event_count_range": [0, 32],
        "query_count_range": [0, 32],
        "event_delta_range": [0, 1000],
        "threshold_range": [1, 512000],
        "range_convention": "Inclusive zero-based ranges for both events and queries.",
        "maximum_valid_length": 195,
        "maximum_parseable_length": 196,
        "invalid_input_result": -1,
    }
    expected_output = {
        "kind": "signed_64_bit_integer",
        "encoding": "weighted sum of one-based query IDs and one-based answer codes",
        "result_range": [0, 17952],
        "invalid_input_result": -1,
    }
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "parallel_binary_search_range_threshold"
            or workload.get("function_symbol") != "parallel_binary_search_range_threshold"
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("source", {}).get("url") != SOURCE_URL
            or contract != expected_input
            or output != expected_output
            or contract.get("maximum_valid_length") != primary.MAX_VALID_INPUT_LENGTH
            or contract.get("maximum_parseable_length") != primary.MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("workspace", {}).get("bytes") != primary.WORKSPACE_BYTES):
        raise ValueError("workload identity, ABI, provenance, or profile bounds differ")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain cases")
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            raise ValueError("each fixture requires a string id")
        if case["id"] in seen:
            raise ValueError(f"duplicate fixture id: {case['id']}")
        seen.add(case["id"])
        values = case.get("input_values")
        if not isinstance(values, list):
            raise ValueError(f"fixture input_values must be a list: {case['id']}")
        input_length = case.get("input_length")
        input_is_null = case.get("input_is_null", False)
        if (type(input_is_null) is not bool
                or type(input_length) is not int
                or len(values) > primary.MAX_PARSEABLE_INPUT_LENGTH
                or (input_is_null and (values or input_length != 0))
                or (not input_is_null and input_length != len(values))):
            raise ValueError(f"fixture framing differs: {case['id']}")
        options = {
            "input_is_null": input_is_null,
            "input_length": input_length,
        }
        expected = case.get("expected_result")
        if type(expected) is not int:
            raise ValueError(f"fixture expected_result must be an integer: {case['id']}")
        if primary.expected_result(values, **options) != expected:
            raise ValueError(f"primary oracle disagrees with fixture: {case['id']}")
        if independent.expected_result(values, **options) != expected:
            raise ValueError(f"independent oracle disagrees with fixture: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if SOURCE_URL not in readme or SOURCE_URL not in rights or "clean-room" not in rights:
        raise ValueError("README or rights note omits source attribution")
    if len(PORTS) != 10:
        raise ValueError("inventory must list all ten supported languages")
    for relative in PORTS:
        source = ROOT / relative
        if not source.is_file():
            raise ValueError(f"port is missing: {relative}")
        if "parallel_binary_search_range_threshold" not in source.read_text(encoding="utf-8"):
            raise ValueError(f"exported symbol is missing: {relative}")
        if relative not in readme:
            raise ValueError(f"README does not link port: {relative}")
    return len(cases)


def static_issues() -> list[str]:
    """Expose the scalar runner's package review hook without running ports."""
    try:
        verify_workload()
    except Exception as error:
        return [f"parallel_binary_search_range_threshold package: {error}"]
    return []
