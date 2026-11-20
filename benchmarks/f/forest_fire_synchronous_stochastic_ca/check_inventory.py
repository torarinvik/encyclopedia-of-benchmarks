"""Check package paths and declared bounds without executing native ports."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "forest_fire_synchronous_stochastic_ca"
PORTS = {
    "c": "c/f/forest_fire_synchronous_stochastic_ca.c",
    "c3": "c3/f/forest_fire_synchronous_stochastic_ca.c3",
    "cpp": "cpp/f/forest_fire_synchronous_stochastic_ca.cpp",
    "elisa": "elisa/f/forest_fire_synchronous_stochastic_ca.elisa",
    "mojo": "mojo/f/forest_fire_synchronous_stochastic_ca.mojo",
    "nim": "nim/f/forest_fire_synchronous_stochastic_ca.nim",
    "odin": "odin/f/forest_fire_synchronous_stochastic_ca.odin",
    "rust": "rust/f/forest_fire_synchronous_stochastic_ca.rs",
    "v": "v/f/forest_fire_synchronous_stochastic_ca.v",
    "zig": "zig/f/forest_fire_synchronous_stochastic_ca.zig",
}


def verify_static_inventory() -> list[str]:
    errors: list[str] = []
    inventory = json.loads((PACKAGE / "inventory.json").read_text())
    workload = json.loads((PACKAGE / "workload.json").read_text())
    expected_paths = {language: f"../../../{path}" for language, path in PORTS.items()}
    if inventory.get("ports") != expected_paths:
        errors.append("inventory port map mismatch")
    for data, label in ((inventory, "inventory"), (workload, "workload")):
        if data.get("algorithm") != SYMBOL or data.get("function_symbol") != SYMBOL:
            errors.append(f"{label} algorithm or symbol mismatch")
        if data.get("abi") != "i64_array_bytes_output":
            errors.append(f"{label} ABI mismatch")
    if workload.get("input", {}).get("maximum_input_length") != 1095:
        errors.append("maximum parseable input length mismatch")
    if workload.get("contract", {}).get("maximum_valid_input_length") != 1094:
        errors.append("maximum valid input length mismatch")
    if workload.get("output", {}).get("maximum_output_bytes") != 712:
        errors.append("maximum output bound mismatch")
    if workload.get("workspace", {}).get("bytes") != 192:
        errors.append("workspace bound mismatch")
    if 2 * 64 + 3 * 8 > workload.get("workspace", {}).get("bytes", 0):
        errors.append("fixed scratch exceeds workspace bound")
    if 8 * (1 + 3 * 8 + 64) != workload.get("output", {}).get("maximum_output_bytes"):
        errors.append("output bound proof mismatch")
    if len(PORTS) != 10:
        errors.append("expected exactly ten native ports")

    for language, relative in PORTS.items():
        source = ROOT / relative
        if not source.is_file():
            errors.append(f"missing {language} port: {relative}")
        elif SYMBOL not in source.read_text():
            errors.append(f"missing export symbol in {language}: {relative}")

    required = (
        "README.md", "RIGHTS.md", "INVENTORY.md", "primary_oracle.py",
        "independent_oracle.py", "workload.json", "inventory.json",
        "check_inventory.py", "verify_workload.py",
    )
    for name in required:
        if not (PACKAGE / name).is_file():
            errors.append(f"missing package artifact: {name}")

    ids: set[str] = set()
    for case in workload.get("cases", []):
        case_id = case.get("id", "<unnamed>")
        if case_id in ids:
            errors.append(f"duplicate workload case id: {case_id}")
        ids.add(case_id)
        values = case.get("input_values", [])
        if case.get("input_length") != len(values):
            errors.append(f"input length mismatch for case {case_id}")
        if case.get("output_capacity", 712) > 712:
            errors.append(f"capacity exceeds maximum for case {case_id}")
        if "expected_result" not in case or not isinstance(case.get("expected_output_hex"), str):
            errors.append(f"missing pinned output for case {case_id}")
        if case.get("input_is_null") and case.get("expected_result") != -1:
            errors.append(f"null input result mismatch for case {case_id}")
        if case.get("output_is_null") and case.get("expected_result") != -2:
            errors.append(f"null output result mismatch for case {case_id}")

    primary = (PACKAGE / "primary_oracle.py").read_text()
    independent = (PACKAGE / "independent_oracle.py").read_text()
    for label, source in (("primary", primary), ("independent", independent)):
        for constant in ("MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1",
                         "MAX_OUTPUT_BYTES = 8 * (1 + 3 * MAX_STEPS + MAX_CELLS)",
                         "WORKSPACE_BYTES = 192"):
            if constant not in source:
                errors.append(f"{label} oracle is missing {constant}")
    if "burning_neighbor = False" not in primary or "adjacent = [[False" not in independent:
        errors.append("reference implementations are not structurally distinct")
    return errors


if __name__ == "__main__":
    problems = verify_static_inventory()
    if problems:
        raise SystemExit("\n".join(problems))
