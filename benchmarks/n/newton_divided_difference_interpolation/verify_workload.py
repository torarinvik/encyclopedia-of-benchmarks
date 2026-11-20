"""Static package and fixture inventory for Newton divided differences."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent_result
from .primary_oracle import MAX_NODES, MAX_PARSEABLE_INPUT_LENGTH, MAX_VALID_INPUT_LENGTH, MODULUS, expected_result

ROOT = Path(__file__).resolve().parents[3]
LANGUAGES = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}


def verify_workload() -> None:
    package = Path(__file__).resolve().parent
    workload = json.loads((package / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "newton_divided_difference_interpolation"
            or workload.get("function_symbol") != "newton_divided_difference_interpolation"
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or MAX_NODES != 12 or MODULUS != 998_244_353):
        raise ValueError("Newton divided-difference metadata differs from its bounded contract")
    readme = (package / "README.md").read_text(encoding="utf-8")
    if "https://dlmf.nist.gov/3.3" not in readme:
        raise ValueError("Newton divided-difference provenance is missing")
    for language, extension in LANGUAGES.items():
        source = ROOT / language / "n" / f"newton_divided_difference_interpolation.{extension}"
        if not source.is_file() or "newton_divided_difference_interpolation" not in source.read_text(encoding="utf-8"):
            raise ValueError(f"missing language port: {source}")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("Newton divided-difference workload has no fixtures")
    for case in cases:
        values = case.get("input_values")
        is_null = case.get("input_is_null", False)
        length = case.get("input_length", len(values) if isinstance(values, list) else None)
        if (not isinstance(values, list) or type(is_null) is not bool
                or type(length) is not int or length != len(values)
                or len(values) > MAX_PARSEABLE_INPUT_LENGTH
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                       for value in values)
                or is_null and values):
            raise ValueError(f"invalid fixture framing: {case.get('id')}")
        if (case.get("expected_result") != expected_result(values, is_null, length)
                or case.get("expected_result") != independent_result(values, is_null, length)):
            raise ValueError(f"reference disagreement in fixture: {case.get('id')}")
