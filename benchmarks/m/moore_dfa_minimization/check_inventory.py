"""Static source/metadata inventory checker; deliberately not run in drafting."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/m/moore_dfa_minimization"
ALGORITHM = "moore_dfa_minimization"
LANGUAGE_PATHS = {
    "c": "c/m/moore_dfa_minimization.c",
    "c3": "c3/m/moore_dfa_minimization.c3",
    "cpp": "cpp/m/moore_dfa_minimization.cpp",
    "elisa": "elisa/m/moore_dfa_minimization.elisa",
    "mojo": "mojo/m/moore_dfa_minimization.mojo",
    "nim": "nim/m/moore_dfa_minimization.nim",
    "odin": "odin/m/moore_dfa_minimization.odin",
    "rust": "rust/m/moore_dfa_minimization.rs",
    "v": "v/m/moore_dfa_minimization.v",
    "zig": "zig/m/moore_dfa_minimization.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package metadata: {error}"]
    if (inventory.get("algorithm") != ALGORITHM or inventory.get("function_symbol") != ALGORITHM
            or inventory.get("abi") != "i64_array_scalar" or inventory.get("languages") != LANGUAGE_PATHS):
        issues.append("inventory identity, ABI, or language map differs from contract")
    for name in inventory.get("metadata", []):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package metadata: {name}")
    for language, relative in LANGUAGE_PATHS.items():
        source = ROOT / relative
        if not source.is_file():
            issues.append(f"missing {language} source: {relative}")
        elif ALGORITHM not in source.read_text(encoding="utf-8"):
            issues.append(f"export marker missing in {relative}")
    case_ids = [case.get("id") for case in workload.get("cases", []) if isinstance(case, dict)]
    if len(case_ids) != len(set(case_ids)) or set(case_ids) != set(inventory.get("fixture_ids", [])):
        issues.append("workload and inventory fixture IDs differ")
    bounds = inventory.get("contract", {})
    if (bounds.get("maximum_valid_input_length") != 28 or bounds.get("maximum_parseable_input_length") != 29
            or bounds.get("maximum_result") != 2264924159 or bounds.get("workspace_bytes") != 4096
            or workload.get("workspace", {}).get("bytes") != 4096):
        issues.append("recorded bounds differ from the package contract")
    return issues


def check_inventory() -> None:
    issues = static_issues()
    if issues:
        raise ValueError("\n".join(issues))


if __name__ == "__main__":
    check_inventory()
