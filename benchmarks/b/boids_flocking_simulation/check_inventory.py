"""Static inventory review for the bounded Boids benchmark package."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SYMBOL = "boids_flocking_simulation"
EXPECTED_PORTS = [
    "c/b/boids_flocking_simulation.c",
    "c3/b/boids_flocking_simulation.c3",
    "cpp/b/boids_flocking_simulation.cpp",
    "elisa/b/boids_flocking_simulation.elisa",
    "mojo/b/boids_flocking_simulation.mojo",
    "nim/b/boids_flocking_simulation.nim",
    "odin/b/boids_flocking_simulation.odin",
    "rust/b/boids_flocking_simulation.rs",
    "v/b/boids_flocking_simulation.v",
    "zig/b/boids_flocking_simulation.zig",
]
EXPECTED_REFERENCES = [
    "benchmarks/boids_flocking_simulation_oracle.py",
    "benchmarks/b/boids_flocking_simulation/independent_reference.py",
]


def inventory_errors() -> list[str]:
    inventory_path = PACKAGE / "INVENTORY.json"
    workload_path = PACKAGE / "workload.json"
    errors: list[str] = []
    if not inventory_path.is_file():
        return ["package inventory is missing"]
    if not workload_path.is_file():
        return ["bounded workload is missing"]

    inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
    workload = json.loads(workload_path.read_text(encoding="utf-8"))
    if (inventory.get("algorithm") != SYMBOL
            or inventory.get("function_symbol") != SYMBOL
            or inventory.get("abi") != "i64_array_bytes_output"):
        errors.append("inventory algorithm, symbol, or ABI differs from the package contract")
    if inventory.get("ports") != EXPECTED_PORTS:
        errors.append("port paths differ from the pinned ten-language inventory")
    for path in EXPECTED_PORTS:
        source_path = ROOT / path
        if not source_path.is_file():
            errors.append(f"missing language port: {path}")
        elif SYMBOL not in source_path.read_text(encoding="utf-8"):
            errors.append(f"exported symbol is absent from language port: {path}")

    if inventory.get("references") != EXPECTED_REFERENCES:
        errors.append("reference paths differ from the pinned inventory")
    for path in EXPECTED_REFERENCES:
        if not (ROOT / path).is_file():
            errors.append(f"missing reference: {path}")

    if inventory.get("static_inventory") != (
            "benchmarks/b/boids_flocking_simulation/check_inventory.py"):
        errors.append("static checker path differs from inventory")
    if inventory.get("workload_verifier") != (
            "benchmarks/b/boids_flocking_simulation/verify_workload.py"):
        errors.append("workload verifier path differs from inventory")
    for field in ("static_inventory", "workload_verifier"):
        path = inventory.get(field)
        if isinstance(path, str) and not (ROOT / path).is_file():
            errors.append(f"missing package review artifact: {path}")
    if (workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != inventory.get("abi")):
        errors.append("workload algorithm, symbol, or ABI differs from inventory")
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    workspace = workload.get("workspace", {})
    if (input_spec.get("maximum_valid_length") != 69
            or input_spec.get("maximum_parseable_length") != 70
            or output_spec.get("maximum_bytes") != 256
            or workspace.get("bytes") != 1280
            or inventory.get("workspace_bytes") != 1280
            or inventory.get("maximum_output_bytes") != 256):
        errors.append("input, output, or workspace bounds differ from the bounded profile")

    cases = workload.get("cases", [])
    if [case.get("id") for case in cases] != inventory.get("fixtures"):
        errors.append("workload fixture IDs differ from inventory")
    for case in cases:
        values = case.get("input_values", [])
        if (not case.get("input_is_null", False)
                and case.get("input_length") != len(values)):
            errors.append(f"input length metadata differs: {case.get('id')}")
        output_hex = case.get("expected_output_hex")
        result = case.get("expected_result")
        if not isinstance(output_hex, str) or len(output_hex) % 2:
            errors.append(f"expected output is not valid hexadecimal text: {case.get('id')}")
            continue
        try:
            output = bytes.fromhex(output_hex)
        except ValueError:
            errors.append(f"expected output contains invalid hexadecimal: {case.get('id')}")
            continue
        if type(result) is not int or (result >= 0 and len(output) != result) or (
                result < 0 and output):
            errors.append(f"result and expected byte length differ: {case.get('id')}")
        if result >= 0 and case.get("output_capacity", 0) < result:
            errors.append(f"fixture capacity is too small: {case.get('id')}")

    readme_path = PACKAGE / "README.md"
    rights_path = PACKAGE / "RIGHTS.md"
    if not readme_path.is_file() or not rights_path.is_file():
        errors.append("package guide or rights note is missing")
    else:
        readme = readme_path.read_text(encoding="utf-8")
        rights = rights_path.read_text(encoding="utf-8")
        source_url = "https://www.red3d.com/cwr/papers/1987/SIGGRAPH87.pdf"
        if source_url not in readme or source_url not in rights:
            errors.append("Reynolds paper provenance is missing from package docs")
        for path in EXPECTED_PORTS:
            if path not in readme:
                errors.append(f"README is missing a language port link: {path}")

    return errors


def static_issues() -> list[str]:
    """Compatibility name used by package-aware suite integrations."""
    return inventory_errors()

