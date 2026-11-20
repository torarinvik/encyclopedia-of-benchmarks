"""Static source/workload metadata inventory for the Pagoda package."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks" / "p" / "pagoda_meldable_priority_queue"
LANGUAGES = {
    "c": "c/p/pagoda_meldable_priority_queue.c",
    "c3": "c3/p/pagoda_meldable_priority_queue.c3",
    "cpp": "cpp/p/pagoda_meldable_priority_queue.cpp",
    "elisa": "elisa/p/pagoda_meldable_priority_queue.elisa",
    "mojo": "mojo/p/pagoda_meldable_priority_queue.mojo",
    "nim": "nim/p/pagoda_meldable_priority_queue.nim",
    "odin": "odin/p/pagoda_meldable_priority_queue.odin",
    "rust": "rust/p/pagoda_meldable_priority_queue.rs",
    "v": "v/pagoda_meldable_priority_queue.v",
    "zig": "zig/p/pagoda_meldable_priority_queue.zig",
}


def static_issues():
    issues = []
    inventory = json.loads((PACKAGE / "INVENTORY.json").read_text())
    workload = json.loads((PACKAGE / "workload.json").read_text())
    expected_sources = list(LANGUAGES.values())
    if inventory.get("sources") != expected_sources:
        issues.append("INVENTORY.json source paths differ from the ten-language map")
    for language, relative in LANGUAGES.items():
        if not (ROOT / relative).is_file():
            issues.append(f"missing {language} source: {relative}")
    for artifact in inventory.get("artifacts", []):
        if not (ROOT / artifact).is_file():
            issues.append(f"missing package artifact: {artifact}")
    if workload.get("function_symbol") != "pagoda_meldable_priority_queue":
        issues.append("workload function symbol mismatch")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("workload ABI mismatch")
    input_bounds = workload.get("input", {})
    if input_bounds.get("maximum_valid_values") != 258:
        issues.append("workload maximum valid input mismatch")
    if input_bounds.get("maximum_parseable_values") != 259:
        issues.append("workload maximum parseable input mismatch")
    if workload.get("workspace", {}).get("bytes") != 4096:
        issues.append("workload workspace bound mismatch")
    if workload.get("output", {}).get("maximum_result") != inventory.get("bounds", {}).get("max_result"):
        issues.append("workload and inventory result bounds differ")
    found_maximum_frame = False
    found_maximum_nodes = False
    for case in workload.get("cases", []):
        values = case.get("input_values")
        if not isinstance(values, list) or type(case.get("input_length")) is not int:
            issues.append(f"{case.get('id')}: missing input framing")
        else:
            if type(case.get("input_is_null", False)) is not bool:
                issues.append(f"{case.get('id')}: input_is_null must be boolean")
            elif not case.get("input_is_null", False) and case["input_length"] != len(values):
                issues.append(f"{case.get('id')}: non-null input length mismatch")
            if case.get("id") == "maximum_frame":
                found_maximum_frame = case["input_length"] == 258 and len(values) == 258
            if case.get("id") == "maximum_nodes":
                found_maximum_nodes = case["input_length"] == 258 and len(values) == 258
    if not found_maximum_frame:
        issues.append("maximum-frame workload case missing or incorrectly sized")
    if not found_maximum_nodes:
        issues.append("maximum-node workload case missing or incorrectly sized")
    return issues
