"""Static package inventory and workload contract checker; does not build ports."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .primary_oracle import MAX_OUTPUT_BYTES, WORKSPACE_BYTES
except ImportError:  # Direct invocation from the package directory.
    from primary_oracle import MAX_OUTPUT_BYTES, WORKSPACE_BYTES

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
LANGUAGE_PORTS = {
    "C": ROOT / "c/c/create_maximum_number.c",
    "C3": ROOT / "c3/c/create_maximum_number.c3",
    "C++": ROOT / "cpp/c/create_maximum_number.cpp",
    "Elisa": ROOT / "elisa/c/create_maximum_number.elisa",
    "Mojo": ROOT / "mojo/c/create_maximum_number.mojo",
    "Nim": ROOT / "nim/c/create_maximum_number.nim",
    "Odin": ROOT / "odin/c/create_maximum_number.odin",
    "Rust": ROOT / "rust/c/create_maximum_number.rs",
    "V": ROOT / "v/c/create_maximum_number.v",
    "Zig": ROOT / "zig/c/create_maximum_number.zig",
}


def check_inventory() -> list[str]:
    errors: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            errors.append(f"missing package file: {name}")
    for language, path in LANGUAGE_PORTS.items():
        if not path.is_file():
            errors.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "create_maximum_number" not in path.read_text(encoding="utf-8"):
            errors.append(f"{language} port does not declare the benchmark symbol")

    elisa = LANGUAGE_PORTS["Elisa"]
    if elisa.is_file():
        source = elisa.read_text(encoding="utf-8")
        if "view[i64]" not in source or "UnsafePointer" in source or "ptr " in source:
            errors.append("Elisa port must use safe views internally and avoid raw pointer helpers")

    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return errors + [f"invalid workload JSON: {error}"]
    if workload.get("algorithm") != "create_maximum_number":
        errors.append("workload algorithm name does not match the package")
    if workload.get("function_symbol") != "create_maximum_number":
        errors.append("workload symbol does not match the package")
    if workload.get("abi") != "i64_array_bytes_output":
        errors.append("workload ABI is not i64_array_bytes_output")
    if workload.get("input", {}).get("maximum_valid_length") != 15:
        errors.append("workload maximum input length must be 15")
    maximum_output = workload.get("output", {}).get("maximum_output_bytes")
    workspace_bytes = workload.get("workspace", {}).get("bytes")
    if maximum_output != MAX_OUTPUT_BYTES:
        errors.append("workload maximum output differs from the primary oracle")
    if workspace_bytes != WORKSPACE_BYTES:
        errors.append("workspace metadata differs from the primary oracle")

    for case in workload.get("cases", []):
        if not case.get("input_is_null", False):
            values = case.get("input_values", [])
            if case.get("input_length") != len(values):
                errors.append(f"{case.get('id')}: declared input length differs from its values")
        try:
            payload = bytes.fromhex(case.get("expected_output_hex", ""))
        except ValueError:
            errors.append(f"{case.get('id')}: expected output is not hexadecimal")
            continue
        result = case.get("expected_result")
        if isinstance(result, int) and result >= 0 and len(payload) != result:
            errors.append(f"{case.get('id')}: successful result differs from byte count")
        if any(digit > 9 for digit in payload):
            errors.append(f"{case.get('id')}: output contains a non-digit byte")
    return errors


if __name__ == "__main__":
    failures = check_inventory()
    if failures:
        raise SystemExit("\n".join(failures))
