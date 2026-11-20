"""Static source and metadata inventory; intentionally not run."""

import json
from pathlib import Path


PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
EXPECTED_SOURCES = {
    f"{language}/p/packet_switching_random_schedule.{extension}"
    for language, extension in (
        ("c", "c"), ("c3", "c3"), ("cpp", "cpp"), ("elisa", "elisa"),
        ("mojo", "mojo"), ("nim", "nim"), ("odin", "odin"),
        ("rust", "rs"), ("v", "v"), ("zig", "zig"),
    )
}


def check_inventory() -> None:
    inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    if (inventory.get("algorithm") != "packet_switching_random_schedule"
            or inventory.get("abi") != "i64_array_bytes_output"
            or set(inventory.get("sources", [])) != EXPECTED_SOURCES):
        raise ValueError("inventory identity, ABI, or ten-language sources differ")
    for relative in inventory["sources"]:
        path = ROOT / relative
        if not path.is_file():
            raise FileNotFoundError(relative)
        if "packet_switching_random_schedule" not in path.read_text(encoding="utf-8"):
            raise ValueError(f"exported symbol missing from {relative}")
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
    if workload["output"]["maximum_bytes"] != inventory["maximum_output_bytes"]:
        raise ValueError("output bound differs")
    if workload["workspace"]["bytes"] != inventory["workspace_bytes"]:
        raise ValueError("workspace bound differs")


if __name__ == "__main__":
    check_inventory()
