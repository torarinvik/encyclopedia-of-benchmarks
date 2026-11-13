"""Static workload and ten-port inventory review for persistent range kth."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent / "p" / "persistent_segment_tree_range_kth"
ROOT = PACKAGE.parents[2]
SOURCE_URL = "https://cp-algorithms.com/data_structures/segment_tree.html"
PORTS = (
    "c/p/persistent_segment_tree_range_kth.c",
    "c3/p/persistent_segment_tree_range_kth.c3",
    "cpp/p/persistent_segment_tree_range_kth.cpp",
    "elisa/p/persistent_segment_tree_range_kth.elisa",
    "mojo/p/persistent_segment_tree_range_kth.mojo",
    "nim/p/persistent_segment_tree_range_kth.nim",
    "odin/p/persistent_segment_tree_range_kth.odin",
    "rust/p/persistent_segment_tree_range_kth.rs",
    "v/p/persistent_segment_tree_range_kth.v",
    "zig/p/persistent_segment_tree_range_kth.zig",
)


def _load(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load oracle source: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def verify_workload() -> int:
    primary = _load("persistent_range_kth_primary", PACKAGE / "primary_oracle.py")
    independent = _load("persistent_range_kth_independent", PACKAGE / "independent_oracle.py")
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    invalid = -(1 << 63)
    expected_input = {
        "kind": "signed_64_bit_integer_array",
        "encoding": "[N,Q,values[N],(L,R,K)*Q]",
        "n_range": [1, 32], "q_range": [0, 32], "value_range": [-1000, 1000],
        "maximum_valid_length": 130, "maximum_parseable_length": 131,
        "invalid_input_result": invalid,
    }
    expected_output = {
        "kind": "signed_64_bit_integer",
        "encoding": "weighted sum of selected values; zero when Q is zero",
        "result_range": [-528000, 528000], "invalid_input_result": invalid,
    }
    if (workload.get("schema_version") != 1
            or workload.get("id") != "persistent-prefix-histogram-range-kth-i64-array-scalar-v1"
            or workload.get("algorithm") != "persistent_segment_tree_range_kth"
            or workload.get("function_symbol") != "persistent_segment_tree_range_kth"
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("source", {}).get("url") != SOURCE_URL
            or workload.get("input") != expected_input
            or workload.get("output") != expected_output
            or workload.get("workspace", {}).get("bytes") != 4096
            or primary.MAX_N != 32 or primary.MAX_Q != 32
            or primary.VALUE_MIN != -1000 or primary.VALUE_MAX != 1000
            or primary.MAX_VALID_INPUT_LENGTH != 130
            or primary.MAX_PARSEABLE_INPUT_LENGTH != 131
            or primary.MAX_NODES != 193 or primary.WORKSPACE_BYTES != 4096
            or independent.MAX_N != primary.MAX_N or independent.MAX_Q != primary.MAX_Q
            or independent.VALUE_MIN != primary.VALUE_MIN
            or independent.VALUE_MAX != primary.VALUE_MAX
            or independent.MAX_VALID_INPUT_LENGTH != primary.MAX_VALID_INPUT_LENGTH
            or independent.MAX_PARSEABLE_INPUT_LENGTH != primary.MAX_PARSEABLE_INPUT_LENGTH
            or independent.WORKSPACE_BYTES != primary.WORKSPACE_BYTES):
        raise ValueError("workload identity, bounds, provenance, or oracle profile differs")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain cases")
    seen: set[str] = set()
    maximum_seen = False
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            raise ValueError("each fixture requires a string id")
        if case["id"] in seen:
            raise ValueError(f"duplicate fixture id: {case['id']}")
        seen.add(case["id"])
        values = case.get("input_values")
        length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int
                or type(is_null) is not bool or len(values) > 131
                or (is_null and (values or length != 0))
                or (not is_null and length != len(values))):
            raise ValueError(f"fixture framing differs: {case.get('id')}")
        if len(values) == 130 and case["id"] == "maximum-size-repeated-values":
            maximum_seen = True
        expected = case.get("expected_result")
        if type(expected) is not int:
            raise ValueError(f"fixture result must be an integer: {case['id']}")
        options = {"input_is_null": is_null, "input_length": length}
        if primary.expected_result(values, **options) != expected:
            raise ValueError(f"primary oracle disagrees with fixture: {case['id']}")
        if independent.expected_result(values, **options) != expected:
            raise ValueError(f"independent oracle disagrees with fixture: {case['id']}")
    if not maximum_seen:
        raise ValueError("maximum-size fixture is required")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if SOURCE_URL not in readme or SOURCE_URL not in rights or "clean-room" not in readme.lower():
        raise ValueError("README or rights note omits clean-room source attribution")
    if len(PORTS) != 10:
        raise ValueError("inventory must include all ten supported languages")
    for relative in PORTS:
        source = ROOT / relative
        if not source.is_file():
            raise ValueError(f"port is missing: {relative}")
        text = source.read_text(encoding="utf-8")
        if "persistent_segment_tree_range_kth" not in text or relative not in readme:
            raise ValueError(f"port symbol or README link is missing: {relative}")
    return len(cases)


def static_issues() -> list[str]:
    """Expose the scalar runner's package review hook without running ports."""
    try:
        verify_workload()
    except Exception as error:
        return [f"persistent_segment_tree_range_kth package: {error}"]
    return []
