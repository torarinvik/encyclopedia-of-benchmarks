"""Static workload, oracle, provenance, and ten-port inventory review."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PRIMARY_URL = "https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.graph_hashing.weisfeiler_lehman_graph_hash.html"
INDEPENDENT_URL = "https://jmlr.org/papers/v12/shervashidze11a.html"
PORTS = (
    "c/w/weisfeiler_lehman_color_refinement.c",
    "c3/w/weisfeiler_lehman_color_refinement.c3",
    "cpp/w/weisfeiler_lehman_color_refinement.cpp",
    "elisa/w/weisfeiler_lehman_color_refinement.elisa",
    "mojo/w/weisfeiler_lehman_color_refinement.mojo",
    "nim/w/weisfeiler_lehman_color_refinement.nim",
    "odin/w/weisfeiler_lehman_color_refinement.odin",
    "rust/w/weisfeiler_lehman_color_refinement.rs",
    "v/w/weisfeiler_lehman_color_refinement.v",
    "zig/w/weisfeiler_lehman_color_refinement.zig",
)


def _load(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load oracle source: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def verify_workload() -> int:
    primary = _load("wl_primary", PACKAGE / "primary_oracle.py")
    independent = _load("wl_independent", PACKAGE / "independent_oracle.py")
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    expected_input = {
        "kind": "signed_64_bit_integer_array",
        "encoding": "[N,adjacency_mask_0,...,adjacency_mask_(N-1)]",
        "vertex_count_range": [0, 8],
        "maximum_valid_length": 9,
        "maximum_parseable_length": 10,
        "mask_range_for_N": "0 through 2^N-1",
        "invalid_input_result": -1,
    }
    expected_output = {
        "kind": "signed_64_bit_integer",
        "encoding": "stable per-vertex canonical colors packed in base 9",
        "result_range": [0, 43046720],
        "invalid_input_result": -1,
    }
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "weisfeiler_lehman_color_refinement"
            or workload.get("function_symbol") != "weisfeiler_lehman_color_refinement"
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("source", {}).get("url") != PRIMARY_URL
            or workload.get("input") != expected_input
            or workload.get("output") != expected_output
            or workload.get("workspace", {}).get("bytes") != 4096
            or primary.MAX_VERTICES != 8
            or primary.MAX_VALID_INPUT_LENGTH != 9
            or primary.MAX_PARSEABLE_INPUT_LENGTH != 10
            or primary.WORKSPACE_BYTES != 4096
            or independent.MAX_VERTICES != primary.MAX_VERTICES
            or independent.MAX_VALID_INPUT_LENGTH != primary.MAX_VALID_INPUT_LENGTH
            or independent.MAX_PARSEABLE_INPUT_LENGTH != primary.MAX_PARSEABLE_INPUT_LENGTH
            or independent.WORKSPACE_BYTES != primary.WORKSPACE_BYTES):
        raise ValueError("workload identity, ABI, provenance, or bounds differ")

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
        input_length = case.get("input_length")
        input_is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(input_is_null) is not bool
                or type(input_length) is not int
                or len(values) > primary.MAX_PARSEABLE_INPUT_LENGTH
                or (input_is_null and (values or input_length != 0))
                or (not input_is_null and input_length != len(values))):
            raise ValueError(f"fixture framing differs: {case.get('id')}")
        options = {"input_is_null": input_is_null, "input_length": input_length}
        expected = case.get("expected_result")
        if type(expected) is not int:
            raise ValueError(f"fixture result must be an integer: {case['id']}")
        if primary.expected_result(values, **options) != expected:
            raise ValueError(f"primary oracle disagrees with fixture: {case['id']}")
        if independent.expected_result(values, **options) != expected:
            raise ValueError(f"independent oracle disagrees with fixture: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if (PRIMARY_URL not in readme or PRIMARY_URL not in rights
            or INDEPENDENT_URL not in readme or INDEPENDENT_URL not in rights
            or "hash-free" not in readme.lower()):
        raise ValueError("README or rights note omits provenance or hash-free semantics")
    if len(PORTS) != 10:
        raise ValueError("inventory must list all ten supported languages")
    for relative in PORTS:
        source = ROOT / relative
        if not source.is_file():
            raise ValueError(f"port is missing: {relative}")
        if "weisfeiler_lehman_color_refinement" not in source.read_text(encoding="utf-8"):
            raise ValueError(f"exported symbol is missing: {relative}")
        if relative not in readme:
            raise ValueError(f"README does not link port: {relative}")
    return len(cases)


def static_issues() -> list[str]:
    """Expose the scalar runner's package review hook without running ports."""
    try:
        verify_workload()
    except Exception as error:
        return [f"weisfeiler_lehman_color_refinement package: {error}"]
    return []
