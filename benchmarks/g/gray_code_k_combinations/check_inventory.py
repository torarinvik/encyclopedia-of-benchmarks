"""Static source and workload verifier; it never builds or runs language ports."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import evaluate as independent_evaluate
    from .primary_oracle import evaluate as primary_evaluate
except ImportError:
    from independent_oracle import evaluate as independent_evaluate
    from primary_oracle import evaluate as primary_evaluate

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = {
    "c": "c/g/gray_code_k_combinations.c",
    "c3": "c3/g/gray_code_k_combinations.c3",
    "cpp": "cpp/g/gray_code_k_combinations.cpp",
    "elisa": "elisa/g/gray_code_k_combinations.elisa",
    "mojo": "mojo/g/gray_code_k_combinations.mojo",
    "nim": "nim/g/gray_code_k_combinations.nim",
    "odin": "odin/g/gray_code_k_combinations.odin",
    "rust": "rust/g/gray_code_k_combinations.rs",
    "v": "v/g/gray_code_k_combinations.v",
    "zig": "zig/g/gray_code_k_combinations.zig",
}


def verify_static_inventory() -> list[str]:
    errors: list[str] = []
    inventory = json.loads((PACKAGE / "inventory.json").read_text())
    workload = json.loads((PACKAGE / "workload.json").read_text())
    if inventory.get("ports") != {language: f"../../../{path}" for language, path in PORTS.items()}:
        errors.append("inventory port map mismatch")
    if inventory.get("abi") != "i64_array_bytes_output":
        errors.append("inventory ABI mismatch")
    if workload.get("algorithm") != "gray_code_k_combinations":
        errors.append("workload algorithm mismatch")
    if workload.get("abi") != "i64_array_bytes_output":
        errors.append("workload ABI mismatch")
    if workload.get("output", {}).get("maximum_output_bytes") != 1850:
        errors.append("workload maximum output size mismatch")
    if len(PORTS) != 10:
        errors.append("expected exactly ten language ports")
    for language, relative in PORTS.items():
        source = ROOT / relative
        if not source.is_file():
            errors.append(f"missing {language} port: {relative}")
        elif "gray_code_k_combinations" not in source.read_text():
            errors.append(f"missing export symbol in {language}: {relative}")
    for required in ("README.md", "RIGHTS.md", "primary_oracle.py",
                     "independent_oracle.py", "inventory.json"):
        if not (PACKAGE / required).is_file():
            errors.append(f"missing package artifact: {required}")
    for case in workload.get("cases", []):
        if case.get("input_length") != len(case.get("input_values", [])) and not case.get("input_is_null"):
            errors.append(f"input length mismatch in case {case.get('id')}")
        if case.get("input_is_null"):
            if case.get("expected_result") != -1:
                errors.append(f"null-input result mismatch in case {case.get('id')}")
            continue
        if case.get("output_is_null"):
            if case.get("expected_result") != -2:
                errors.append(f"null-output result mismatch in case {case.get('id')}")
            continue
        values = case.get("input_values", [])
        primary_result, primary_bytes = primary_evaluate(values)
        independent_result, independent_bytes = independent_evaluate(values)
        if primary_result != independent_result or primary_bytes != independent_bytes:
            errors.append(f"oracle disagreement in case {case.get('id')}")
        if primary_result >= 0 and case.get("output_capacity", 1850) < len(primary_bytes):
            if case.get("expected_result") != -2 or case.get("expected_output_hex") != "":
                errors.append(f"short-output result mismatch in case {case.get('id')}")
            continue
        if primary_result != case.get("expected_result"):
            errors.append(f"expected result mismatch in case {case.get('id')}")
        if primary_bytes.hex() != case.get("expected_output_hex"):
            errors.append(f"expected bytes mismatch in case {case.get('id')}")
    return errors


if __name__ == "__main__":
    problems = verify_static_inventory()
    if problems:
        raise SystemExit("\n".join(problems))
