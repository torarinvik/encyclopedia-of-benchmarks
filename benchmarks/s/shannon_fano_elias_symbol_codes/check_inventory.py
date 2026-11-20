"""Static source and metadata inventory checker; not run while drafting."""

import json
from pathlib import Path

try:
    from .verify_workload import REQUIRED_CASES, workload_issues
except ImportError:
    from verify_workload import REQUIRED_CASES, workload_issues

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/s/shannon_fano_elias_symbol_codes"
ALGORITHM = "shannon_fano_elias_symbol_codes"
LANGUAGE_PATHS = {
    "c": "c/s/shannon_fano_elias_symbol_codes.c",
    "c3": "c3/s/shannon_fano_elias_symbol_codes.c3",
    "cpp": "cpp/s/shannon_fano_elias_symbol_codes.cpp",
    "elisa": "elisa/s/shannon_fano_elias_symbol_codes.elisa",
    "mojo": "mojo/s/shannon_fano_elias_symbol_codes.mojo",
    "nim": "nim/s/shannon_fano_elias_symbol_codes.nim",
    "odin": "odin/s/shannon_fano_elias_symbol_codes.odin",
    "rust": "rust/s/shannon_fano_elias_symbol_codes.rs",
    "v": "v/s/shannon_fano_elias_symbol_codes.v",
    "zig": "zig/s/shannon_fano_elias_symbol_codes.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package metadata: {error}"]
    if (inventory.get("algorithm") != ALGORITHM
            or inventory.get("function_symbol") != ALGORITHM
            or inventory.get("abi") != "i64_array_bytes_output"
            or inventory.get("languages") != LANGUAGE_PATHS):
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
    if set(inventory.get("fixture_ids", [])) != REQUIRED_CASES:
        issues.append("inventory fixture IDs differ from the statically reviewed set")
    contract = inventory.get("contract", {})
    if (contract.get("maximum_valid_input_length") != 9
            or contract.get("maximum_parseable_input_length") != 10
            or contract.get("maximum_output_bytes") != 17
            or contract.get("workspace_bytes") != 1024
            or workload.get("workspace", {}).get("bytes") != 1024):
        issues.append("inventory and workload bounds differ from the package contract")
    issues.extend(workload_issues(workload))
    return issues


def check_inventory() -> None:
    issues = static_issues()
    if issues:
        raise ValueError("\n".join(issues))


if __name__ == "__main__":
    check_inventory()
