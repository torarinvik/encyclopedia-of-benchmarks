"""Static source and metadata inventory for minimum_weight_cycle_floyd."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks" / "m" / "minimum_weight_cycle_floyd"
LANGUAGES = {
    "c": "c/m/minimum_weight_cycle_floyd.c",
    "c3": "c3/m/minimum_weight_cycle_floyd.c3",
    "cpp": "cpp/m/minimum_weight_cycle_floyd.cpp",
    "elisa": "elisa/m/minimum_weight_cycle_floyd.elisa",
    "mojo": "mojo/m/minimum_weight_cycle_floyd.mojo",
    "nim": "nim/m/minimum_weight_cycle_floyd.nim",
    "odin": "odin/m/minimum_weight_cycle_floyd.odin",
    "rust": "rust/m/minimum_weight_cycle_floyd.rs",
    "v": "v/m/minimum_weight_cycle_floyd.v",
    "zig": "zig/m/minimum_weight_cycle_floyd.zig",
}


def static_issues():
    issues = []
    inventory = json.loads((PACKAGE / "INVENTORY.json").read_text())
    workload = json.loads((PACKAGE / "workload.json").read_text())
    expected_sources = list(LANGUAGES.values())
    if inventory.get("sources") != expected_sources:
        issues.append("INVENTORY.json source paths differ from the ten language map")
    for language, relative in LANGUAGES.items():
        if not (ROOT / relative).is_file():
            issues.append(f"missing {language} source: {relative}")
    for artifact in inventory.get("artifacts", []):
        if not (ROOT / artifact).is_file():
            issues.append(f"missing package artifact: {artifact}")
    if workload.get("function_symbol") != "minimum_weight_cycle_floyd":
        issues.append("workload function symbol mismatch")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("workload ABI mismatch")
    if workload.get("input", {}).get("maximum_valid_length") != 110:
        issues.append("workload valid input bound mismatch")
    if workload.get("input", {}).get("maximum_parseable_length") != 111:
        issues.append("workload parseable input bound mismatch")
    if workload.get("output", {}).get("maximum_bytes") != 8:
        issues.append("workload output bound mismatch")
    if workload.get("workspace", {}).get("bytes") != 4096:
        issues.append("workload workspace bound mismatch")
    for case in workload.get("cases", []):
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"{case.get('id')}: input framing mismatch")
        if case.get("expected_result", 0) >= 0:
            try:
                payload = bytes.fromhex(case.get("expected_output_hex", ""))
            except ValueError:
                issues.append(f"{case.get('id')}: invalid output hex")
            else:
                if case["expected_result"] != len(payload) or len(payload) != 8:
                    issues.append(f"{case.get('id')}: valid output must be exactly 8 bytes")
        elif case.get("expected_output_hex", "") != "":
            issues.append(f"{case.get('id')}: error case must not write output")
    return issues
