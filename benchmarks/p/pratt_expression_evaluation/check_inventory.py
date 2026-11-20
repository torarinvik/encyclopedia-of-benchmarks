"""Static source and package-file inventory for Pratt expression evaluation."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks" / "p" / "pratt_expression_evaluation"
LANGUAGES = {
    "c": "c/p/pratt_expression_evaluation.c",
    "c3": "c3/p/pratt_expression_evaluation.c3",
    "cpp": "cpp/p/pratt_expression_evaluation.cpp",
    "elisa": "elisa/p/pratt_expression_evaluation.elisa",
    "mojo": "mojo/p/pratt_expression_evaluation.mojo",
    "nim": "nim/p/pratt_expression_evaluation.nim",
    "odin": "odin/p/pratt_expression_evaluation.odin",
    "rust": "rust/p/pratt_expression_evaluation.rs",
    "v": "v/p/pratt_expression_evaluation.v",
    "zig": "zig/p/pratt_expression_evaluation.zig",
}


def static_issues():
    issues = []
    inventory = json.loads((PACKAGE / "INVENTORY.json").read_text())
    workload = json.loads((PACKAGE / "workload.json").read_text())
    if inventory.get("native_paths") != list(LANGUAGES.values()):
        issues.append("INVENTORY.json native paths differ from the ten-language map")
    for language, relative in LANGUAGES.items():
        if not (ROOT / relative).is_file():
            issues.append(f"missing {language} source: {relative}")
    for relative in inventory.get("package_files", []):
        if not (PACKAGE / relative).is_file():
            issues.append(f"missing package artifact: {relative}")
    if workload.get("function_symbol") != "pratt_expression_evaluation":
        issues.append("workload function symbol mismatch")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("workload ABI mismatch")
    if workload.get("input", {}).get("maximum_tokens") != 15:
        issues.append("workload token bound mismatch")
    if len(workload.get("cases", [])) < 1:
        issues.append("workload has no fixtures")
    return issues


def check_inventory():
    issues = static_issues()
    if issues:
        raise ValueError("\n".join(issues))
