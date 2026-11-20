"""Static CORDIC package/source inventory review; does not run benchmark code."""

from __future__ import annotations

import json
import math
from pathlib import Path


PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
ALGORITHM = "cordic_rotation_fixed_point"
ABI = "i64_array_bytes_output"
PORTS = {
    "c": "c/c/cordic_rotation_fixed_point.c",
    "c3": "c3/c/cordic_rotation_fixed_point.c3",
    "cpp": "cpp/c/cordic_rotation_fixed_point.cpp",
    "elisa": "elisa/c/cordic_rotation_fixed_point.elisa",
    "mojo": "mojo/c/cordic_rotation_fixed_point.mojo",
    "nim": "nim/c/cordic_rotation_fixed_point.nim",
    "odin": "odin/c/cordic_rotation_fixed_point.odin",
    "rust": "rust/c/cordic_rotation_fixed_point.rs",
    "v": "v/c/cordic_rotation_fixed_point.v",
    "zig": "zig/c/cordic_rotation_fixed_point.zig",
}
REFERENCES = ("primary_oracle.py", "independent_oracle.py")
METADATA = (
    "README.md", "RIGHTS.md", "workload.json", "INVENTORY.json",
    "check_inventory.py",
)
MAX_VALID_INPUT_VALUES = 2
MAX_PARSEABLE_INPUT_VALUES = 3
MAX_OUTPUT_BYTES = 24
OUTPUT_WORDS = 3
WORKSPACE_BYTES = 128


def _read_json(path: Path, issues: list[str], label: str) -> dict:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        issues.append(f"cannot read {label}: {error}")
        return {}
    if not isinstance(value, dict):
        issues.append(f"{label} must contain a JSON object")
        return {}
    return value


def static_issues() -> list[str]:
    """Return metadata, fixture-framing, and ten-port inventory mismatches."""
    issues: list[str] = []
    inventory = _read_json(PACKAGE / "INVENTORY.json", issues, "INVENTORY.json")
    workload = _read_json(PACKAGE / "workload.json", issues, "workload.json")

    if inventory.get("algorithm") != ALGORITHM:
        issues.append("inventory algorithm ID mismatch")
    if inventory.get("function_symbol") != ALGORITHM:
        issues.append("inventory function symbol mismatch")
    if inventory.get("abi") != ABI:
        issues.append("inventory ABI mismatch")
    if inventory.get("languages") != PORTS:
        issues.append("inventory ten-language path map mismatch")
    if inventory.get("references") != list(REFERENCES):
        issues.append("inventory reference list mismatch")
    if inventory.get("metadata") != list(METADATA):
        issues.append("inventory metadata list mismatch")
    if inventory.get("static_checker") != "check_inventory.py":
        issues.append("inventory static-checker path mismatch")
    inventory_source = inventory.get("source", {})
    if not isinstance(inventory_source, dict):
        issues.append("inventory source provenance must be an object")
        inventory_source = {}

    contract = inventory.get("contract", {})
    if not isinstance(contract, dict):
        issues.append("inventory contract must be an object")
        contract = {}
    expected_contract = {
        "maximum_valid_input_values": MAX_VALID_INPUT_VALUES,
        "maximum_parseable_input_values": MAX_PARSEABLE_INPUT_VALUES,
        "maximum_output_bytes": MAX_OUTPUT_BYTES,
        "workspace_bytes": WORKSPACE_BYTES,
        "maximum_stages": 16,
        "fixed_point_scale": 1_000_000_000,
    }
    for field, expected in expected_contract.items():
        if contract.get(field) != expected:
            issues.append(f"inventory contract field differs: {field}")

    for relative in PORTS.values():
        source = ROOT / relative
        if not source.is_file():
            issues.append(f"missing language source: {relative}")
            continue
        try:
            text = source.read_text(encoding="utf-8")
        except OSError as error:
            issues.append(f"cannot read language source {relative}: {error}")
            continue
        if ALGORITHM not in text:
            issues.append(f"export symbol missing from language source: {relative}")

    for relative in REFERENCES:
        path = PACKAGE / relative
        if not path.is_file():
            issues.append(f"missing reference: {relative}")
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except OSError as error:
            issues.append(f"cannot read reference {relative}: {error}")
            continue
        if "WORKSPACE_BYTES = 128" not in text:
            issues.append(f"workspace constant missing from reference: {relative}")
        for argument in (
            "output_is_null: bool = False",
            "input_is_null: bool = False",
            "input_length: int | None = None",
        ):
            if argument not in text:
                issues.append(f"reference ABI argument missing in {relative}: {argument}")

    for relative in METADATA:
        if not (PACKAGE / relative).is_file():
            issues.append(f"missing package metadata/artifact: {relative}")

    if workload.get("algorithm") != ALGORITHM:
        issues.append("workload algorithm ID mismatch")
    if workload.get("function_symbol") != ALGORITHM:
        issues.append("workload function symbol mismatch")
    if workload.get("abi") != ABI:
        issues.append("workload ABI mismatch")
    input_contract = workload.get("input", {})
    output_contract = workload.get("output", {})
    workspace = workload.get("workspace", {})
    if not isinstance(input_contract, dict):
        issues.append("workload input contract must be an object")
        input_contract = {}
    if not isinstance(output_contract, dict):
        issues.append("workload output contract must be an object")
        output_contract = {}
    if not isinstance(workspace, dict):
        issues.append("workload workspace must be an object")
        workspace = {}
    if input_contract.get("exact_length") != MAX_VALID_INPUT_VALUES:
        issues.append("workload exact input length mismatch")
    if input_contract.get("maximum_valid_input_values") != MAX_VALID_INPUT_VALUES:
        issues.append("workload valid input bound mismatch")
    if input_contract.get("maximum_parseable_input_values") != MAX_PARSEABLE_INPUT_VALUES:
        issues.append("workload parseable input bound mismatch")
    if output_contract.get("kind") != "float64_vector":
        issues.append("workload output kind mismatch")
    if output_contract.get("maximum_output_elements") != OUTPUT_WORDS:
        issues.append("workload binary64 word count mismatch")
    if output_contract.get("maximum_output_bytes") != MAX_OUTPUT_BYTES:
        issues.append("workload output byte bound mismatch")
    encoding = output_contract.get("encoding", "")
    if (not isinstance(encoding, str) or "24 bytes" not in encoding
            or "8 bytes per word" not in encoding):
        issues.append("workload output encoding must specify three 8-byte words")
    if workspace.get("bytes") != WORKSPACE_BYTES:
        issues.append("workload workspace bound mismatch")
    workload_source = workload.get("source", {})
    if not isinstance(workload_source, dict):
        issues.append("workload source provenance must be an object")
        workload_source = {}
    for inventory_key, workload_key in (("url", "discovery_url"), ("primary_url", "primary_url")):
        expected_url = inventory_source.get(inventory_key)
        if not isinstance(expected_url, str) or workload_source.get(workload_key) != expected_url:
            issues.append(f"workload/inventory provenance URL mismatch: {inventory_key}")

    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        for language, relative in PORTS.items():
            if f"](../../../{relative})" not in readme:
                issues.append(f"README source link missing for {language}")
        if "three IEEE-754 binary64 words" not in readme or "24 bytes (8 bytes per word)" not in readme:
            issues.append("README output framing must state three binary64 words in 24 bytes")
        for source_url in (inventory_source.get("url"), inventory_source.get("primary_url")):
            if isinstance(source_url, str) and source_url not in readme:
                issues.append(f"README provenance URL missing: {source_url}")
    rights_path = PACKAGE / "RIGHTS.md"
    if rights_path.is_file():
        rights = rights_path.read_text(encoding="utf-8")
        for source_url in (inventory_source.get("url"), inventory_source.get("primary_url")):
            if isinstance(source_url, str) and source_url not in rights:
                issues.append(f"rights provenance URL missing: {source_url}")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        issues.append("workload must contain a nonempty case list")
        return issues
    for case in cases:
        case_id = case.get("id", "<unnamed>") if isinstance(case, dict) else "<non-object>"
        if not isinstance(case, dict):
            issues.append(f"workload case is not an object: {case_id}")
            continue
        values = case.get("input_values")
        input_length = case.get("input_length")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        capacity = case.get("output_capacity")
        result = case.get("expected_result")
        expected = case.get("expected_output")
        if not isinstance(values, list) or type(input_length) is not int:
            issues.append(f"invalid input framing metadata: {case_id}")
            continue
        if type(input_is_null) is not bool or type(output_is_null) is not bool:
            issues.append(f"null flag must be Boolean: {case_id}")
        if input_length != len(values):
            issues.append(f"input buffer length mismatch: {case_id}")
        if input_length < 0 or input_length > MAX_PARSEABLE_INPUT_VALUES:
            issues.append(f"input frame exceeds parseable bound: {case_id}")
        if input_is_null and (input_length != 0 or values):
            issues.append(f"null input case has a nonempty frame: {case_id}")
        if not all(type(value) is int and -(1 << 63) <= value < (1 << 63) for value in values):
            issues.append(f"input words are not signed 64-bit integers: {case_id}")
        if type(capacity) is not int or capacity < 0:
            issues.append(f"invalid output capacity: {case_id}")
        if type(result) is not int or result not in (-2, -1, MAX_OUTPUT_BYTES):
            issues.append(f"invalid expected result code: {case_id}")
        if not isinstance(expected, list):
            issues.append(f"expected output must be a list: {case_id}")
            continue
        if any(type(value) not in (int, float) or not math.isfinite(value) for value in expected):
            issues.append(f"expected output contains a non-finite/non-numeric value: {case_id}")
        if result == MAX_OUTPUT_BYTES:
            if len(expected) != OUTPUT_WORDS:
                issues.append(f"successful fixture must contain three binary64 words: {case_id}")
            if input_is_null or output_is_null or type(capacity) is not int or capacity < MAX_OUTPUT_BYTES:
                issues.append(f"successful fixture has null/short framing: {case_id}")
            if len(expected) * 8 != result:
                issues.append(f"successful fixture byte length is not 24: {case_id}")
        else:
            if expected:
                issues.append(f"error fixture must have empty output: {case_id}")
            if result == -2 and not output_is_null and type(capacity) is int and capacity >= MAX_OUTPUT_BYTES:
                issues.append(f"capacity error lacks null/short output cause: {case_id}")
        encoded = case.get("expected_output_hex")
        if encoded is not None and (
            not isinstance(encoded, str)
            or type(result) is int and len(encoded) != max(result, 0) * 2
        ):
            issues.append(f"serialized expected-output length mismatch: {case_id}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
