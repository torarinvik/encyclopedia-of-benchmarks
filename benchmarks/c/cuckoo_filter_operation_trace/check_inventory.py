"""Static source and metadata inventory for the Cuckoo Filter trace."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "cuckoo_filter_operation_trace"
SOURCE_URL = "https://www.cs.cmu.edu/~dga/papers/cuckoo-conext2014.pdf"
PORTS = {
    "c": "c/c/cuckoo_filter_operation_trace.c",
    "c3": "c3/c/cuckoo_filter_operation_trace.c3",
    "cpp": "cpp/c/cuckoo_filter_operation_trace.cpp",
    "elisa": "elisa/c/cuckoo_filter_operation_trace.elisa",
    "mojo": "mojo/c/cuckoo_filter_operation_trace.mojo",
    "nim": "nim/c/cuckoo_filter_operation_trace.nim",
    "odin": "odin/c/cuckoo_filter_operation_trace.odin",
    "rust": "rust/c/cuckoo_filter_operation_trace.rs",
    "v": "v/c/cuckoo_filter_operation_trace.v",
    "zig": "zig/c/cuckoo_filter_operation_trace.zig",
}


def check_inventory() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
        inventory_text = (PACKAGE / "INVENTORY.md").read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package metadata: {error}"]

    if (inventory.get("algorithm") != SYMBOL
            or inventory.get("abi") != "i64_array_bytes_output"
            or inventory.get("maximum_valid_input_words") != 97
            or inventory.get("maximum_parseable_input_words") != 98
            or inventory.get("maximum_output_bytes") != 256
            or inventory.get("workspace_bytes") != 1024):
        issues.append("inventory identity or bounded contract differs")
    if set(inventory.get("sources", ())) != set(PORTS.values()):
        issues.append("inventory source paths do not match the ten language ports")
    if workload.get("algorithm") != SYMBOL or workload.get("abi") != "i64_array_bytes_output":
        issues.append("workload identity or ABI differs")
    if workload.get("source", {}).get("url") != SOURCE_URL:
        issues.append("workload citation differs from the pinned CoNEXT paper")
    if SOURCE_URL not in readme or SOURCE_URL not in rights:
        issues.append("primary source citation is missing from package documentation")
    for artifact in inventory.get("artifacts", ()):
        if not (PACKAGE / artifact).is_file():
            issues.append(f"missing package artifact: {artifact}")

    for language, relative in PORTS.items():
        source_path = ROOT / relative
        if not source_path.is_file():
            issues.append(f"missing {language} source: {relative}")
            continue
        source = source_path.read_text(encoding="utf-8")
        if SYMBOL not in source:
            issues.append(f"exported symbol is missing from {relative}")
        if relative not in inventory_text:
            issues.append(f"INVENTORY.md omits {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README omits the {language} port link")
    return issues


static_issues = check_inventory
