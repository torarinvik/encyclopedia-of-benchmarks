"""Static package/path check; this file is authored, not run."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = {
    "c": "c/g/goodstein_sequence_bounded_prefix.c",
    "c3": "c3/g/goodstein_sequence_bounded_prefix.c3",
    "cpp": "cpp/g/goodstein_sequence_bounded_prefix.cpp",
    "elisa": "elisa/g/goodstein_sequence_bounded_prefix.elisa",
    "mojo": "mojo/g/goodstein_sequence_bounded_prefix.mojo",
    "nim": "nim/g/goodstein_sequence_bounded_prefix.nim",
    "odin": "odin/g/goodstein_sequence_bounded_prefix.odin",
    "rust": "rust/g/goodstein_sequence_bounded_prefix.rs",
    "v": "v/g/goodstein_sequence_bounded_prefix.v",
    "zig": "zig/g/goodstein_sequence_bounded_prefix.zig",
}


def verify_static_inventory() -> list[str]:
    errors: list[str] = []
    inventory = json.loads((PACKAGE / "inventory.json").read_text())
    workload = json.loads((PACKAGE / "workload.json").read_text())
    expected_paths = {language: f"../../../{path}" for language, path in PORTS.items()}
    if inventory.get("ports") != expected_paths:
        errors.append("inventory port map mismatch")
    if inventory.get("abi") != "i64_array_bytes_output":
        errors.append("inventory ABI mismatch")
    if inventory.get("function_symbol") != "goodstein_sequence_bounded_prefix":
        errors.append("inventory function symbol mismatch")
    if workload.get("algorithm") != "goodstein_sequence_bounded_prefix":
        errors.append("workload algorithm mismatch")
    if workload.get("abi") != "i64_array_bytes_output":
        errors.append("workload ABI mismatch")
    if workload.get("input", {}).get("maximum_valid_input_length") != 2:
        errors.append("valid input bound mismatch")
    if workload.get("input", {}).get("maximum_parseable_input_length") != 3:
        errors.append("parseable input bound mismatch")
    if workload.get("output", {}).get("maximum_output_bytes") != 144:
        errors.append("output bound mismatch")
    if workload.get("workspace", {}).get("bytes") != 512:
        errors.append("workspace bound mismatch")
    if len(PORTS) != 10:
        errors.append("expected exactly ten language ports")
    for language, relative in PORTS.items():
        source = ROOT / relative
        if not source.is_file():
            errors.append(f"missing {language} port: {relative}")
        elif "goodstein_sequence_bounded_prefix" not in source.read_text():
            errors.append(f"missing exported symbol in {language}: {relative}")
    for required in (
        "README.md", "RIGHTS.md", "INVENTORY.md", "inventory.json",
        "workload.json", "primary_oracle.py", "independent_oracle.py",
        "verify_workload.py",
    ):
        if not (PACKAGE / required).is_file():
            errors.append(f"missing package artifact: {required}")
    return errors


if __name__ == "__main__":
    problems = verify_static_inventory()
    if problems:
        raise SystemExit("\n".join(problems))
