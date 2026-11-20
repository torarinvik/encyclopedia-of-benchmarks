"""Static package inventory checker; intentionally not run during drafting."""

from __future__ import annotations

import json
from pathlib import Path


PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
EXPECTED_LANGUAGES = {
    "c": "c/e/euclid_mullin_sequence.c",
    "c3": "c3/e/euclid_mullin_sequence.c3",
    "cpp": "cpp/e/euclid_mullin_sequence.cpp",
    "elisa": "elisa/e/euclid_mullin_sequence.elisa",
    "mojo": "mojo/e/euclid_mullin_sequence.mojo",
    "nim": "nim/e/euclid_mullin_sequence.nim",
    "odin": "odin/e/euclid_mullin_sequence.odin",
    "rust": "rust/e/euclid_mullin_sequence.rs",
    "v": "v/e/euclid_mullin_sequence.v",
    "zig": "zig/e/euclid_mullin_sequence.zig",
}
EXPECTED_TERMS = {
    "first-term": (1, 2),
    "second-term": (2, 3),
    "fourth-term": (4, 43),
    "nonmonotone-term": (5, 13),
    "least-factor-not-euclid-number": (7, 5),
    "maximum-supported-index": (8, 6_221_671),
}


def check_inventory() -> None:
    inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    if (inventory.get("algorithm") != "euclid_mullin_sequence"
            or inventory.get("abi") != "i64_array_scalar"
            or inventory.get("function_symbol") != "euclid_mullin_sequence"
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
    if (workload["input"].get("n_range") != [1, inventory["maximum_n"]]
            or workload["input"].get("maximum_valid_length")
                != inventory["maximum_valid_input_length"]
            or workload["input"].get("maximum_parseable_length")
                != inventory["maximum_parseable_input_length"]
            or workload["output"].get("valid_result_range")
                != [2, inventory["maximum_result"]]
            or workload["workspace"].get("bytes") != inventory["workspace_bytes"]
            or inventory["maximum_candidate"] != 6_221_671):
        raise ValueError("workload bounds, candidate cap, or workspace differ")

    actual_terms = {
        case["id"]: (case["input_values"][0], case["expected_result"])
        for case in workload["cases"]
        if case.get("input_length") == 1 and len(case["input_values"]) == 1
    }
    for case_id, expected in EXPECTED_TERMS.items():
        if actual_terms.get(case_id) != expected:
            raise ValueError(f"published term fixture differs: {case_id}")


if __name__ == "__main__":
    check_inventory()
