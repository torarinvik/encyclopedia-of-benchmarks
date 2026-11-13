"""Static workload, oracle, provenance, and ten-port inventory review."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SOURCE_URL = "https://www.timothywang.ca/OI-wiki/misc/cdq-divide/"
PORTS = (
    "c/cdq_three_dimensional_dominance.c",
    "c3/cdq_three_dimensional_dominance.c3",
    "cpp/cdq_three_dimensional_dominance.cpp",
    "elisa/cdq_three_dimensional_dominance.elisa",
    "mojo/cdq_three_dimensional_dominance.mojo",
    "nim/cdq_three_dimensional_dominance.nim",
    "odin/cdq_three_dimensional_dominance.odin",
    "rust/cdq_three_dimensional_dominance.rs",
    "v/cdq_three_dimensional_dominance.v",
    "zig/cdq_three_dimensional_dominance.zig",
)


def _load(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load oracle source: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def verify_workload() -> int:
    primary = _load("cdq_3d_primary", PACKAGE / "primary_oracle.py")
    independent = _load("cdq_3d_independent", PACKAGE / "independent_oracle.py")
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    expected_input = {
        "kind": "signed_64_bit_integer_array",
        "encoding": "[N,(x,y,z)*N]",
        "point_count_range": [1, 64],
        "coordinate_range": [-1000, 1000],
        "maximum_valid_length": 193,
        "maximum_parseable_length": 194,
        "invalid_input_result": -1,
    }
    expected_output = {
        "kind": "signed_64_bit_integer",
        "encoding": "weighted sum of one-based input indices and per-point weak-dominance counts",
        "result_range": [0, 131040],
        "invalid_input_result": -1,
    }
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "cdq_three_dimensional_dominance"
            or workload.get("function_symbol") != "cdq_three_dimensional_dominance"
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("source", {}).get("url") != SOURCE_URL
            or workload.get("input") != expected_input
            or workload.get("output") != expected_output
            or workload.get("workspace", {}).get("bytes") != primary.WORKSPACE_BYTES
            or primary.MAX_VALID_INPUT_LENGTH != 193
            or primary.MAX_PARSEABLE_INPUT_LENGTH != 194
            or independent.MAX_VALID_INPUT_LENGTH != primary.MAX_VALID_INPUT_LENGTH
            or independent.MAX_PARSEABLE_INPUT_LENGTH != primary.MAX_PARSEABLE_INPUT_LENGTH
            or independent.WORKSPACE_BYTES != primary.WORKSPACE_BYTES
            or primary.MAX_N != 64 or independent.MAX_N != primary.MAX_N
            or primary.COORDINATE_MIN != -1000 or primary.COORDINATE_MAX != 1000
            or independent.COORDINATE_MIN != primary.COORDINATE_MIN
            or independent.COORDINATE_MAX != primary.COORDINATE_MAX):
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
    if SOURCE_URL not in readme or SOURCE_URL not in rights or "clean-room" not in readme.lower():
        raise ValueError("README or rights note omits source attribution")
    if len(PORTS) != 10:
        raise ValueError("inventory must list all ten supported languages")
    for relative in PORTS:
        source = ROOT / relative
        if not source.is_file():
            raise ValueError(f"port is missing: {relative}")
        if "cdq_three_dimensional_dominance" not in source.read_text(encoding="utf-8"):
            raise ValueError(f"exported symbol is missing: {relative}")
        if relative not in readme:
            raise ValueError(f"README does not link port: {relative}")
    return len(cases)


def static_issues() -> list[str]:
    """Expose the scalar runner's package review hook without running ports."""
    try:
        verify_workload()
    except Exception as error:
        return [f"cdq_three_dimensional_dominance package: {error}"]
    return []
