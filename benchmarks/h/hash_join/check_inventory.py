"""Static path and workload checks for the bounded relational hash join."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "hash_join"
LANGUAGE_PORTS = {
    "C": ROOT / "c/h/hash_join.c",
    "C3": ROOT / "c3/h/hash_join.c3",
    "C++": ROOT / "cpp/h/hash_join.cpp",
    "Elisa": ROOT / "elisa/h/hash_join.elisa",
    "Mojo": ROOT / "mojo/h/hash_join.mojo",
    "Nim": ROOT / "nim/h/hash_join.nim",
    "Odin": ROOT / "odin/h/hash_join.odin",
    "Rust": ROOT / "rust/h/hash_join.rs",
    "V": ROOT / "v/h/hash_join.v",
    "Zig": ROOT / "zig/h/hash_join.zig",
}


def check_inventory() -> list[str]:
    errors: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            errors.append(f"missing package file: {name}")

    for language, path in LANGUAGE_PORTS.items():
        if not path.is_file():
            errors.append(f"missing {language} port: {path.relative_to(ROOT)}")
            continue
        if SYMBOL not in path.read_text(encoding="utf-8"):
            errors.append(f"{language} port does not declare {SYMBOL}")

    elisa_path = LANGUAGE_PORTS["Elisa"]
    if elisa_path.is_file():
        elisa = elisa_path.read_text(encoding="utf-8")
        if "view[i64]" not in elisa or "mutable view[u8]" not in elisa:
            errors.append("Elisa internals must use safe views")
        if "UnsafePointer" in elisa or "ptr " in elisa:
            errors.append("Elisa port must not add raw pointer helpers")

    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return errors + [f"invalid workload JSON: {error}"]
    if workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL:
        errors.append("workload algorithm and symbol must match the package")
    if workload.get("abi") != "i64_array_bytes_output":
        errors.append("workload ABI must be i64_array_bytes_output")
    input_metadata = workload.get("input", {})
    if input_metadata.get("rows_per_relation_range") != [0, 8]:
        errors.append("each relation must be bounded to 0..8 rows")
    if input_metadata.get("maximum_valid_length") != 18:
        errors.append("maximum valid input length must be 18")
    if input_metadata.get("maximum_parseable_length") != 19:
        errors.append("maximum parseable input length must be 19")
    if workload.get("output", {}).get("maximum_output_bytes") != 64:
        errors.append("maximum output must be 64 bytes")
    if workload.get("workspace", {}).get("bytes") != 1024:
        errors.append("workspace contract must be 1024 bytes")

    found_max_valid = False
    found_max_parseable = False
    for case in workload.get("cases", []):
        case_id = case.get("id", "<unnamed>")
        values = case.get("input_values", [])
        if not case.get("input_is_null", False) and case.get("input_length") != len(values):
            errors.append(f"{case_id}: declared input length differs from its values")
        if case_id == "maximum_rows_and_matches":
            found_max_valid = len(values) == 18 and values[:2] == [8, 8] and case.get("expected_result") == 64
        if case_id == "maximum_parseable_trailing_value":
            found_max_parseable = len(values) == 19 and case.get("expected_result") == -1
        try:
            payload = bytes.fromhex(case.get("expected_output_hex", ""))
        except ValueError:
            errors.append(f"{case_id}: expected output is not hexadecimal")
            continue
        result = case.get("expected_result")
        if isinstance(result, int) and result >= 0 and len(payload) != result:
            errors.append(f"{case_id}: result differs from output byte count")
        if any(byte > 0x77 for byte in payload):
            errors.append(f"{case_id}: packed row IDs exceed the 0..7 nibble bounds")
    if not found_max_valid:
        errors.append("missing maximum-row, maximum-match workload case")
    if not found_max_parseable:
        errors.append("missing malformed maximum-parseable-length case")
    return errors


if __name__ == "__main__":
    failures = check_inventory()
    if failures:
        raise SystemExit("\n".join(failures))
