"""Static source-path and package-metadata inventory."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "quotient_filter_operation_trace"
PRIMARY_URL = "https://doi.org/10.14778/2350229.2350275"
SECONDARY_URL = "https://doi.org/10.1109/IPDPS.2018.00055"
PORTS = {
    "c": "c/q/quotient_filter_operation_trace.c",
    "c3": "c3/q/quotient_filter_operation_trace.c3",
    "cpp": "cpp/q/quotient_filter_operation_trace.cpp",
    "elisa": "elisa/q/quotient_filter_operation_trace.elisa",
    "mojo": "mojo/q/quotient_filter_operation_trace.mojo",
    "nim": "nim/q/quotient_filter_operation_trace.nim",
    "odin": "odin/q/quotient_filter_operation_trace.odin",
    "rust": "rust/q/quotient_filter_operation_trace.rs",
    "v": "v/q/quotient_filter_operation_trace.v",
    "zig": "zig/q/quotient_filter_operation_trace.zig",
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
            or inventory.get("maximum_valid_input_words") != 65
            or inventory.get("maximum_parseable_input_words") != 66
            or inventory.get("maximum_output_bytes") != 32
            or inventory.get("workspace_bytes") != 256
            or inventory.get("suite_registration") != "integrated"):
        issues.append("inventory identity or bounded contract differs")
    if set(inventory.get("sources", ())) != set(PORTS.values()):
        issues.append("inventory source paths do not match the ten language ports")
    if workload.get("algorithm") != SYMBOL or workload.get("abi") != "i64_array_bytes_output":
        issues.append("workload identity or ABI differs")
    if (workload.get("source", {}).get("url") != PRIMARY_URL
            or workload.get("source", {}).get("secondary_url") != SECONDARY_URL):
        issues.append("workload source citations differ")
    if PRIMARY_URL not in readme or PRIMARY_URL not in rights:
        issues.append("primary source citation is missing from package documentation")
    if SECONDARY_URL not in readme or SECONDARY_URL not in rights:
        issues.append("secondary source citation is missing from package documentation")
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


if __name__ == "__main__":
    problems = check_inventory()
    if problems:
        raise SystemExit("\n".join(problems))
