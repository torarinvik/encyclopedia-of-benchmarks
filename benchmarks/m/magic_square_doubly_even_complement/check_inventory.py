"""Static package-inventory checks; intentionally does not execute references."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ALGORITHM = "magic_square_doubly_even_complement"
EXPECTED_PORTS = {
    "c": "../../../c/m/magic_square_doubly_even_complement.c",
    "c3": "../../../c3/m/magic_square_doubly_even_complement.c3",
    "cpp": "../../../cpp/m/magic_square_doubly_even_complement.cpp",
    "elisa": "../../../elisa/m/magic_square_doubly_even_complement.elisa",
    "mojo": "../../../mojo/m/magic_square_doubly_even_complement.mojo",
    "nim": "../../../nim/m/magic_square_doubly_even_complement.nim",
    "odin": "../../../odin/m/magic_square_doubly_even_complement.odin",
    "rust": "../../../rust/m/magic_square_doubly_even_complement.rs",
    "v": "../../../v/m/magic_square_doubly_even_complement.v",
    "zig": "../../../zig/m/magic_square_doubly_even_complement.zig",
}


def check_inventory() -> None:
    inventory = json.loads((PACKAGE / "inventory.json").read_text())
    if inventory["algorithm"] != ALGORITHM or inventory["abi"] != "scalar_call":
        raise AssertionError("inventory does not identify the bounded scalar package")
    if inventory["function_symbol"] != ALGORITHM or inventory["ports"] != EXPECTED_PORTS:
        raise AssertionError("inventory ports or exported symbol do not match the package")
    for relative_path in EXPECTED_PORTS.values():
        if not (PACKAGE / relative_path).resolve().is_file():
            raise AssertionError(f"missing native port: {relative_path}")
    for relative_path in (
        "README.md",
        "RIGHTS.md",
        "INVENTORY.md",
        "primary_oracle.py",
        "independent_oracle.py",
        "workload.json",
    ):
        if not (PACKAGE / relative_path).is_file():
            raise AssertionError(f"missing package artifact: {relative_path}")

    workload = json.loads((PACKAGE / "workload.json").read_text())
    if workload["algorithm"] != ALGORITHM or workload["abi"] != "scalar_call":
        raise AssertionError("workload does not match the inventory")
    if workload["result"].get("workspace_bytes") != 0:
        raise AssertionError("direct cell generation should use no scratch workspace")
    if len(workload["cases"]) < 8:
        raise AssertionError("workload needs valid orders, rejected orders, and integer extremes")


if __name__ == "__main__":
    check_inventory()
    print("magic_square_doubly_even_complement package inventory is complete")
