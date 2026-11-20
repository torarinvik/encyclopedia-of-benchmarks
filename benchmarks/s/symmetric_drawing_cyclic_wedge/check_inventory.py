"""Static package and fixture inventory; it never calls native ports."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .independent_oracle import expected_output as independent_output
from .primary_oracle import (
    MAX_INPUT_LENGTH,
    MAX_OUTPUT_BYTES,
    MAX_VALID_INPUT_LENGTH,
    WORKSPACE_BYTES,
    expected_output as primary_output,
)

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "symmetric_drawing_cyclic_wedge"
DOI = "10.1007/978-1-4939-2864-4_654"
PORTS = {
    "c": "c/s/symmetric_drawing_cyclic_wedge.c",
    "c3": "c3/s/symmetric_drawing_cyclic_wedge.c3",
    "cpp": "cpp/s/symmetric_drawing_cyclic_wedge.cpp",
    "elisa": "elisa/s/symmetric_drawing_cyclic_wedge.elisa",
    "mojo": "mojo/s/symmetric_drawing_cyclic_wedge.mojo",
    "nim": "nim/s/symmetric_drawing_cyclic_wedge.nim",
    "odin": "odin/s/symmetric_drawing_cyclic_wedge.odin",
    "rust": "rust/s/symmetric_drawing_cyclic_wedge.rs",
    "v": "v/s/symmetric_drawing_cyclic_wedge.v",
    "zig": "zig/s/symmetric_drawing_cyclic_wedge.zig",
}
REQUIRED_CASES = {
    "tetrahedron-one-of-three-cyclic-sectors",
    "six-boundary-wheel-two-step-sector",
    "maximum-eight-vertex-sevenfold-wheel",
    "invalid-reflection-instead-of-rotation",
    "invalid-duplicate-rotation-neighbor",
    "invalid-reversed-outer-face-walk",
    "trailing-word-invalid",
    "maximum-parseable-length-trailing-word",
    "null-input",
    "null-output",
    "short-output",
}


def static_issues(workload: dict[str, Any] | None = None) -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        if workload is None:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package metadata: {error}"]
    if not isinstance(inventory, dict) or not isinstance(workload, dict):
        return ["inventory and workload must be JSON objects"]

    contract = inventory.get("contract", {})
    source = inventory.get("source", {})
    measurement = workload.get("measurement", {})
    expected_measurement = {
        "comparison_model": "i64_array_bytes_output_call",
        "sample_count": 7,
        "warmup_rounds": 2,
        "repetitions_per_sample": 1000,
    }
    if (inventory.get("algorithm") != SYMBOL
            or inventory.get("function_symbol") != SYMBOL
            or inventory.get("abi") != "i64_array_bytes_output"
            or source.get("doi") != DOI
            or contract.get("maximum_valid_input_words") != MAX_VALID_INPUT_LENGTH
            or contract.get("maximum_parseable_input_words") != MAX_INPUT_LENGTH
            or contract.get("maximum_output_bytes") != MAX_OUTPUT_BYTES
            or contract.get("workspace_bytes") != WORKSPACE_BYTES
            or contract.get("measurement") != expected_measurement):
        issues.append("inventory identity, provenance, or bounds differ")

    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    source_spec = workload.get("source", {})
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"
            or source_spec.get("book_chapter_doi") != DOI
            or input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_INPUT_LENGTH
            or output_spec.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES
            or measurement != expected_measurement):
        issues.append("workload identity, ABI, provenance, or bounds differ")

    cases = workload.get("cases")
    if not isinstance(cases, list):
        return issues + ["workload cases must be an array"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid fixture record")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture ID: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        expected = case.get("expected_result")
        expected_hex = case.get("expected_output_hex")
        capacity = case.get("output_capacity")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        if (not isinstance(values, list) or type(length) is not int or length != len(values)
                or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                       for word in values)
                or type(expected) is not int or not isinstance(expected_hex, str)
                or type(input_is_null) is not bool
                or type(output_is_null) is not bool
                or capacity is not None and (type(capacity) is not int or capacity < 0)):
            issues.append(f"invalid fixture fields: {case_id}")
            continue
        data = None if input_is_null else values
        options = {"capacity": capacity, "output_is_null": output_is_null,
                   "input_is_null": input_is_null, "input_length": length}
        primary = primary_output(data, **options)
        independent = independent_output(data, **options)
        try:
            expected_bytes = bytes.fromhex(expected_hex)
        except ValueError:
            issues.append(f"invalid expected output hex: {case_id}")
            continue
        if primary != independent or primary != (expected, expected_bytes):
            issues.append(f"fixture/reference mismatch: {case_id}")
    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing fixture IDs: " + ", ".join(sorted(missing)))

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    normalized = " ".join(readme.split())
    for phrase in (DOI, "Find_Wedge_Cyclic", "54 words", "55", "128 bytes",
                   "rotation_system_planarity_test", "CYN", "clean-room"):
        if phrase.lower() not in normalized.lower():
            issues.append(f"README omits source or contract detail: {phrase}")
    if DOI not in rights or "clean-room" not in rights.lower():
        issues.append("rights/provenance note is incomplete")
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} port: {relative}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing {language} symbol: {relative}")
        if inventory.get("languages", {}).get(language) != relative:
            issues.append(f"inventory path differs for {language}")
        if relative not in readme:
            issues.append(f"README omits {language} source path")
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "check_inventory.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    return issues
