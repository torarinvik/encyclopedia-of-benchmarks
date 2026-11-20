"""Static package inventory checker; intentionally not run during drafting."""

from __future__ import annotations

import json
from pathlib import Path


PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
EXPECTED_LANGUAGES = {
    "c": "c/c/cube_root_proper_divisor_product.c",
    "c3": "c3/c/cube_root_proper_divisor_product.c3",
    "cpp": "cpp/c/cube_root_proper_divisor_product.cpp",
    "elisa": "elisa/c/cube_root_proper_divisor_product.elisa",
    "mojo": "mojo/c/cube_root_proper_divisor_product.mojo",
    "nim": "nim/c/cube_root_proper_divisor_product.nim",
    "odin": "odin/c/cube_root_proper_divisor_product.odin",
    "rust": "rust/c/cube_root_proper_divisor_product.rs",
    "v": "v/c/cube_root_proper_divisor_product.v",
    "zig": "zig/c/cube_root_proper_divisor_product.zig",
}
EXPECTED_CHECKPOINTS = {
    "published-500th-checkpoint": (500, 2526),
    "published-5000th-checkpoint": (5000, 23118),
    "maximum-valid-50000th-stretch": (50000, 223735),
}


def check_inventory() -> None:
    inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    if (inventory.get("algorithm") != "cube_root_proper_divisor_product"
            or inventory.get("abi") != "i64_array_scalar"
            or inventory.get("function_symbol") != "cube_root_proper_divisor_product"
            or inventory.get("languages") != EXPECTED_LANGUAGES):
        raise ValueError("inventory identity, ABI, or ten-language source list differs")

    for relative in inventory["languages"].values():
        if not (ROOT / relative).is_file():
            raise FileNotFoundError(relative)
    for relative in inventory["metadata"]:
        if not (PACKAGE / relative).is_file():
            raise FileNotFoundError(relative)

    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("algorithm") != inventory["algorithm"]
            or workload.get("abi") != inventory["abi"]
            or workload.get("function_symbol") != inventory["function_symbol"]):
        raise ValueError("workload identity differs from inventory")
    if (workload["input"].get("k_range") != [1, inventory["maximum_k"]]
            or workload["input"].get("maximum_valid_length")
                != inventory["maximum_valid_input_length"]
            or workload["input"].get("maximum_parseable_length")
                != inventory["maximum_parseable_input_length"]
            or workload["output"].get("valid_result_range")
                != [1, inventory["maximum_result"]]
            or workload["workspace"].get("bytes") != inventory["workspace_bytes"]
            or inventory["workspace_bytes"] != 2_400_128
            or inventory["prime_prefix_entries"] * inventory["prime_prefix_entry_bytes"]
                + inventory["scalar_allowance_bytes"] != inventory["workspace_bytes"]):
        raise ValueError("workload bounds or workspace differ from inventory")

    actual_cases = {
        case["id"]: (case["input_values"][0], case["expected_result"])
        for case in workload["cases"]
        if case.get("input_length") == 1 and len(case["input_values"]) == 1
    }
    for case_id, expected in EXPECTED_CHECKPOINTS.items():
        if actual_cases.get(case_id) != expected:
            raise ValueError(f"published checkpoint differs: {case_id}")
    if "offset-check" in {case["id"] for case in workload["cases"]}:
        raise ValueError("unattributed offset fixture must not be present")


if __name__ == "__main__":
    check_inventory()
