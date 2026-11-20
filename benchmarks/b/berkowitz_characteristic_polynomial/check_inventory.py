"""Static package inventory checker; not run while drafting."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/b/berkowitz_characteristic_polynomial"
ALGORITHM = "berkowitz_characteristic_polynomial"
LANGUAGE_PATHS = {
    "c": "c/b/berkowitz_characteristic_polynomial.c",
    "c3": "c3/b/berkowitz_characteristic_polynomial.c3",
    "cpp": "cpp/b/berkowitz_characteristic_polynomial.cpp",
    "elisa": "elisa/b/berkowitz_characteristic_polynomial.elisa",
    "mojo": "mojo/b/berkowitz_characteristic_polynomial.mojo",
    "nim": "nim/b/berkowitz_characteristic_polynomial.nim",
    "odin": "odin/b/berkowitz_characteristic_polynomial.odin",
    "rust": "rust/b/berkowitz_characteristic_polynomial.rs",
    "v": "v/b/berkowitz_characteristic_polynomial.v",
    "zig": "zig/b/berkowitz_characteristic_polynomial.zig",
}
CASE_IDS = {
    "single_entry_composite_modulus", "two_by_two_composite_modulus",
    "two_by_two_swap_matrix", "upper_triangular_three_by_three", "zero_matrix",
    "seven_by_seven_identity_composite_modulus", "invalid_zero_dimension",
    "invalid_dimension_too_large", "invalid_modulus_one", "entry_out_of_range",
    "trailing_input", "short_output_capacity", "null_output", "null_input",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "inventory.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package metadata: {error}"]
    if (inventory.get("algorithm") != ALGORITHM
            or inventory.get("function_symbol") != ALGORITHM
            or inventory.get("abi") != "i64_array_bytes_output"
            or inventory.get("languages") != LANGUAGE_PATHS):
        issues.append("inventory identity, ABI, or language map differs from contract")
    for name in inventory.get("metadata", []):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package metadata: {name}")
    for language, relative in LANGUAGE_PATHS.items():
        source = ROOT / relative
        if not source.is_file():
            issues.append(f"missing {language} source: {relative}")
        elif ALGORITHM not in source.read_text(encoding="utf-8"):
            issues.append(f"export marker missing in {relative}")
    cases = workload.get("cases", [])
    ids = [case.get("id") for case in cases]
    if len(ids) != len(set(ids)) or set(ids) != CASE_IDS:
        issues.append("workload fixture IDs differ from the reviewed set")
    if set(inventory.get("fixture_ids", [])) != set(ids):
        issues.append("inventory fixture IDs differ from workload")
    if (workload.get("input", {}).get("maximum_valid_length") != 51
            or workload.get("input", {}).get("maximum_parseable_length") != 52
            or workload.get("output", {}).get("maximum_output_bytes") != 64
            or workload.get("workspace", {}).get("bytes") != 4096
            or inventory.get("contract", {}).get("maximum_valid_input_length") != 51
            or inventory.get("contract", {}).get("maximum_parseable_input_length") != 52
            or inventory.get("contract", {}).get("maximum_output_bytes") != 64
            or inventory.get("contract", {}).get("workspace_bytes") != 4096):
        issues.append("input, output, or workspace bounds differ from contract")
    return issues
