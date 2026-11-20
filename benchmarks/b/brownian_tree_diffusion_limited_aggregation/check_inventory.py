"""Check package paths and declared bounds without executing any benchmark."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "brownian_tree_diffusion_limited_aggregation"
PORTS = {
    "c": "c/b/brownian_tree_diffusion_limited_aggregation.c",
    "c3": "c3/b/brownian_tree_diffusion_limited_aggregation.c3",
    "cpp": "cpp/b/brownian_tree_diffusion_limited_aggregation.cpp",
    "elisa": "elisa/b/brownian_tree_diffusion_limited_aggregation.elisa",
    "mojo": "mojo/b/brownian_tree_diffusion_limited_aggregation.mojo",
    "nim": "nim/b/brownian_tree_diffusion_limited_aggregation.nim",
    "odin": "odin/b/brownian_tree_diffusion_limited_aggregation.odin",
    "rust": "rust/b/brownian_tree_diffusion_limited_aggregation.rs",
    "v": "v/b/brownian_tree_diffusion_limited_aggregation.v",
    "zig": "zig/b/brownian_tree_diffusion_limited_aggregation.zig",
}


def verify_static_inventory() -> list[str]:
    errors: list[str] = []
    inventory = json.loads((PACKAGE / "inventory.json").read_text())
    workload = json.loads((PACKAGE / "workload.json").read_text())

    expected_paths = {language: f"../../../{path}" for language, path in PORTS.items()}
    if inventory.get("ports") != expected_paths:
        errors.append("inventory port map mismatch")
    if inventory.get("algorithm") != SYMBOL or inventory.get("function_symbol") != SYMBOL:
        errors.append("inventory algorithm or symbol mismatch")
    if inventory.get("abi") != "i64_array_bytes_output":
        errors.append("inventory ABI mismatch")
    if inventory.get("workload_verifier") != "verify_workload.py":
        errors.append("workload verifier metadata mismatch")
    if workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL:
        errors.append("workload algorithm or symbol mismatch")
    if workload.get("abi") != "i64_array_bytes_output":
        errors.append("workload ABI mismatch")
    if workload.get("input", {}).get("maximum_input_length") != 4:
        errors.append("maximum input length mismatch")
    if workload.get("output", {}).get("maximum_output_bytes") != 280:
        errors.append("maximum output size mismatch")
    if workload.get("workspace", {}).get("bytes") != 2048:
        errors.append("workspace bound mismatch")
    if 33 * 33 + 2 * 17 * 8 > workload.get("workspace", {}).get("bytes", 0):
        errors.append("fixed scratch exceeds the declared workspace")
    if 8 * (1 + 2 * 17) != workload.get("output", {}).get("maximum_output_bytes"):
        errors.append("maximum output proof mismatch")
    if len(PORTS) != 10:
        errors.append("expected exactly ten language ports")

    for language, relative in PORTS.items():
        source = ROOT / relative
        if not source.is_file():
            errors.append(f"missing {language} port: {relative}")
        elif SYMBOL not in source.read_text():
            errors.append(f"missing export symbol in {language}: {relative}")

    for required in (
        "README.md",
        "RIGHTS.md",
        "INVENTORY.md",
        "primary_oracle.py",
        "independent_oracle.py",
        "workload.json",
        "inventory.json",
        "check_inventory.py",
        "verify_workload.py",
    ):
        if not (PACKAGE / required).is_file():
            errors.append(f"missing package artifact: {required}")

    case_ids: set[str] = set()
    for case in workload.get("cases", []):
        case_id = case.get("id")
        if not isinstance(case_id, str) or case_id in case_ids:
            errors.append(f"missing or repeated workload case id: {case_id}")
        case_ids.add(case_id)
        values = case.get("input_values", [])
        if case.get("input_length") != len(values):
            errors.append(f"input length mismatch in case {case_id}")
        if case.get("output_capacity", 280) > 280:
            errors.append(f"capacity exceeds the package maximum in case {case_id}")
        if "expected_result" not in case or not isinstance(case.get("expected_output_hex"), str):
            errors.append(f"missing pinned result or bytes in case {case_id}")
        if case.get("input_is_null") and case.get("expected_result") != -1:
            errors.append(f"null-input result mismatch in case {case_id}")
        if case.get("output_is_null") and case.get("expected_result") != -2:
            errors.append(f"null-output result mismatch in case {case_id}")

    primary = (PACKAGE / "primary_oracle.py").read_text()
    independent = (PACKAGE / "independent_oracle.py").read_text()
    for source_name, source in (("primary", primary), ("independent", independent)):
        for constant in ("MAX_PARSEABLE_INPUT_LENGTH = 4", "MAX_OUTPUT_BYTES = 280", "WORKSPACE_BYTES = 2048"):
            if constant not in source:
                errors.append(f"{source_name} oracle is missing {constant}")
    if "_precompute_paths" not in independent or "bytearray" not in primary:
        errors.append("reference implementation styles are not visibly distinct")
    return errors


if __name__ == "__main__":
    problems = verify_static_inventory()
    if problems:
        raise SystemExit("\n".join(problems))
