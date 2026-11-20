"""Static file and metadata inventory checker; intentionally not run."""

import json
from pathlib import Path


PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
EXPECTED_SOURCES = {
    f"{language}/{letter}/zobrist_position_hash_trace.{extension}"
    for language, letter, extension in (
        ("c", "z", "c"), ("c3", "z", "c3"), ("cpp", "z", "cpp"),
        ("elisa", "z", "elisa"), ("mojo", "z", "mojo"), ("nim", "z", "nim"),
        ("odin", "z", "odin"), ("rust", "z", "rs"), ("v", "z", "v"),
        ("zig", "z", "zig"),
    )
}


def check_inventory() -> None:
    inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    if (inventory.get("algorithm") != "zobrist_position_hash_trace"
            or inventory.get("abi") != "i64_array_bytes_output"
            or inventory.get("suite_integration")
                != "i64_array_bytes_output runner and verifier"
            or set(inventory.get("sources", [])) != EXPECTED_SOURCES):
        raise ValueError("inventory identity, suite registration, or ten-language sources differ")
    for relative in inventory["sources"]:
        if not (ROOT / relative).is_file():
            raise FileNotFoundError(relative)
    for relative in inventory["references"] + inventory["artifacts"]:
        if not (PACKAGE / relative).is_file():
            raise FileNotFoundError(relative)
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if workload.get("algorithm") != inventory["algorithm"]:
        raise ValueError("workload and inventory algorithm IDs differ")
    if workload["input"]["maximum_valid_length"] != inventory["maximum_valid_input_words"]:
        raise ValueError("valid input bound differs")
    if workload["input"]["maximum_parseable_length"] != inventory["maximum_parseable_input_words"]:
        raise ValueError("parseable input bound differs")
    if workload["output"]["maximum_output_bytes"] != inventory["maximum_output_bytes"]:
        raise ValueError("output bound differs")
    if workload["workspace"]["bytes"] != inventory["workspace_bytes"]:
        raise ValueError("workspace bound differs")


if __name__ == "__main__":
    check_inventory()
