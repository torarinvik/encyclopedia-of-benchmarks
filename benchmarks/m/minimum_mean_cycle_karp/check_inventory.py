"""Static inventory and metadata checks for the bounded Karp cycle-mean package."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "minimum_mean_cycle_karp"
LANGUAGE_PORTS = {
    "C": ROOT / "c/m/minimum_mean_cycle_karp.c",
    "C3": ROOT / "c3/m/minimum_mean_cycle_karp.c3",
    "C++": ROOT / "cpp/m/minimum_mean_cycle_karp.cpp",
    "Elisa": ROOT / "elisa/m/minimum_mean_cycle_karp.elisa",
    "Mojo": ROOT / "mojo/m/minimum_mean_cycle_karp.mojo",
    "Nim": ROOT / "nim/m/minimum_mean_cycle_karp.nim",
    "Odin": ROOT / "odin/m/minimum_mean_cycle_karp.odin",
    "Rust": ROOT / "rust/m/minimum_mean_cycle_karp.rs",
    "V": ROOT / "v/m/minimum_mean_cycle_karp.v",
    "Zig": ROOT / "zig/m/minimum_mean_cycle_karp.zig",
}


def check_inventory() -> list[str]:
    errors: list[str] = []
    required = ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py", "independent_oracle.py")
    for name in required:
        if not (PACKAGE / name).is_file():
            errors.append(f"missing package file: {name}")

    for language, path in LANGUAGE_PORTS.items():
        if not path.is_file():
            errors.append(f"missing {language} port: {path.relative_to(ROOT)}")
            continue
        source = path.read_text(encoding="utf-8")
        if SYMBOL not in source:
            errors.append(f"{language} port does not declare {SYMBOL}")

    elisa_path = LANGUAGE_PORTS["Elisa"]
    if elisa_path.is_file():
        elisa = elisa_path.read_text(encoding="utf-8")
        if "view[i64]" not in elisa or "mutable view[u8]" not in elisa:
            errors.append("Elisa internals must use safe input and output views")
        if "UnsafePointer" in elisa or "ptr " in elisa:
            errors.append("Elisa port must not add raw pointer helpers")

    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return errors + [f"invalid workload JSON: {error}"]

    if workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL:
        errors.append("workload algorithm and exported symbol must match the package")
    if workload.get("abi") != "i64_array_bytes_output":
        errors.append("workload ABI must be i64_array_bytes_output")
    input_metadata = workload.get("input", {})
    if input_metadata.get("vertex_range") != [1, 8]:
        errors.append("workload vertex bound must be 1..8")
    if input_metadata.get("edge_count_range") != "1 through min(16,n*n)":
        errors.append("workload edge bound must be 1..min(16,n*n)")
    if input_metadata.get("maximum_valid_length") != 50:
        errors.append("maximum valid input length must be 50")
    if input_metadata.get("maximum_parseable_length") != 51:
        errors.append("maximum parseable input length must be 51")
    if workload.get("output", {}).get("maximum_output_bytes") != 16:
        errors.append("maximum output size must be 16 bytes")
    if workload.get("workspace", {}).get("bytes") != 2048:
        errors.append("workspace contract must be 2048 bytes")

    found_maximum_input = False
    found_maximum_parseable = False
    for case in workload.get("cases", []):
        case_id = case.get("id", "<unnamed>")
        values = case.get("input_values", [])
        if not case.get("input_is_null", False) and case.get("input_length") != len(values):
            errors.append(f"{case_id}: declared input length differs from its values")
        if case.get("id") == "maximum_input_zero_weight_graph":
            found_maximum_input = len(values) == 50 and values[:2] == [8, 16]
        if case.get("id") == "maximum_parseable_trailing_value":
            found_maximum_parseable = len(values) == 51 and case.get("expected_result") == -1
        try:
            payload = bytes.fromhex(case.get("expected_output_hex", ""))
        except ValueError:
            errors.append(f"{case_id}: expected output is not hexadecimal")
            continue
        result = case.get("expected_result")
        if isinstance(result, int) and result >= 0 and len(payload) != result:
            errors.append(f"{case_id}: success result differs from output byte count")
        if result == 16 and len(payload) != 16:
            errors.append(f"{case_id}: successful cycle-mean result must contain two i64 words")
    if not found_maximum_input:
        errors.append("missing maximum-input 8-vertex, 16-edge case")
    if not found_maximum_parseable:
        errors.append("missing malformed maximum-parseable-length case")
    return errors


if __name__ == "__main__":
    failures = check_inventory()
    if failures:
        raise SystemExit("\n".join(failures))
