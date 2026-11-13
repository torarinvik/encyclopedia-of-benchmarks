"""Static fixture, oracle, provenance, and ten-port inventory checker."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SOURCE_URL = "https://cp-algorithms.com/data_structures/stack_queue_modification.html"
PORTS = (
    "c/m/minimum_queue_two_stacks.c",
    "c3/m/minimum_queue_two_stacks.c3",
    "cpp/m/minimum_queue_two_stacks.cpp",
    "elisa/m/minimum_queue_two_stacks.elisa",
    "mojo/m/minimum_queue_two_stacks.mojo",
    "nim/m/minimum_queue_two_stacks.nim",
    "odin/m/minimum_queue_two_stacks.odin",
    "rust/m/minimum_queue_two_stacks.rs",
    "v/m/minimum_queue_two_stacks.v",
    "zig/m/minimum_queue_two_stacks.zig",
)


def _load(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load oracle source: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def verify_workload() -> int:
    primary = _load("minimum_queue_two_stacks_primary", PACKAGE / "primary_oracle.py")
    independent = _load("minimum_queue_two_stacks_independent", PACKAGE / "independent_oracle.py")
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    input_contract = workload.get("input", {})
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "minimum_queue_two_stacks"
            or workload.get("function_symbol") != "minimum_queue_two_stacks"
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("source", {}).get("url") != SOURCE_URL
            or input_contract.get("maximum_valid_length") != primary.MAX_VALID_INPUT_LENGTH
            or input_contract.get("maximum_parseable_length")
            != primary.MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("workspace", {}).get("bytes") != 512):
        raise ValueError("workload identity, ABI, provenance, or bounds differ")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain cases")
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            raise ValueError("each workload case requires a string id")
        if case["id"] in seen:
            raise ValueError(f"duplicate case id: {case['id']}")
        seen.add(case["id"])
        values = case.get("input_values")
        if not isinstance(values, list):
            raise ValueError(f"input_values must be a list: {case['id']}")
        if not case.get("input_is_null", False) and case.get("input_length") != len(values):
            raise ValueError(f"input framing differs: {case['id']}")
        options = {
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = case.get("expected_result")
        if primary.expected_result(values, **options) != expected:
            raise ValueError(f"primary oracle differs: {case['id']}")
        if independent.expected_result(values, **options) != expected:
            raise ValueError(f"independent oracle differs: {case['id']}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if SOURCE_URL not in readme or SOURCE_URL not in rights or "clean-room" not in rights:
        raise ValueError("README or rights note omits provenance")
    if len(PORTS) != 10:
        raise ValueError("port inventory must include all ten supported languages")
    for relative in PORTS:
        source = ROOT / relative
        if not source.is_file():
            raise ValueError(f"port is missing: {relative}")
        if "minimum_queue_two_stacks" not in source.read_text(encoding="utf-8"):
            raise ValueError(f"entrypoint symbol is missing: {relative}")
        if relative not in readme:
            raise ValueError(f"README does not link port: {relative}")
    return len(cases)


def static_issues() -> list[str]:
    """Expose the scalar-suite adapter without executing language ports."""
    try:
        verify_workload()
    except Exception as error:
        return [f"minimum_queue_two_stacks package: {error}"]
    return []
