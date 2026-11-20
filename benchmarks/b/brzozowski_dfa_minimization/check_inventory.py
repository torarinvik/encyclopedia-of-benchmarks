"""Static package inventory checker; intentionally not run during drafting."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/b/brzozowski_dfa_minimization"
ALGORITHM = "brzozowski_dfa_minimization"
LANGUAGE_PATHS = {
    "c": "c/b/brzozowski_dfa_minimization.c",
    "c3": "c3/b/brzozowski_dfa_minimization.c3",
    "cpp": "cpp/b/brzozowski_dfa_minimization.cpp",
    "elisa": "elisa/b/brzozowski_dfa_minimization.elisa",
    "mojo": "mojo/b/brzozowski_dfa_minimization.mojo",
    "nim": "nim/b/brzozowski_dfa_minimization.nim",
    "odin": "odin/b/brzozowski_dfa_minimization.odin",
    "rust": "rust/b/brzozowski_dfa_minimization.rs",
    "v": "v/b/brzozowski_dfa_minimization.v",
    "zig": "zig/b/brzozowski_dfa_minimization.zig",
}
CASE_IDS = {
    "one_rejecting_state", "one_accepting_state", "two_distinguishable_reachable_states",
    "three_residue_states", "unreachable_states_removed", "empty_language_collapses",
    "invalid_start", "accepting_mask_out_of_range", "invalid_transition", "trailing_word", "null_input",
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
        issues.append("inventory identity, ABI, or language map differs from the contract")
    for name in inventory.get("metadata", []):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package metadata: {name}")
    for language, relative in LANGUAGE_PATHS.items():
        source = ROOT / relative
        if not source.is_file():
            issues.append(f"missing {language} source: {relative}")
        elif ALGORITHM not in source.read_text(encoding="utf-8"):
            issues.append(f"export marker missing in {relative}")
    cases = workload.get("cases", [])
    ids = [case.get("id") for case in cases]
    if len(ids) != len(set(ids)) or set(ids) != CASE_IDS:
        issues.append("workload fixture IDs differ from the reviewed fixture set")
    if set(inventory.get("fixture_ids", [])) != set(ids):
        issues.append("inventory fixture IDs differ from workload")
    if (workload.get("input", {}).get("maximum_valid_length") != 9
            or workload.get("input", {}).get("maximum_parseable_length") != 10
            or workload.get("contract", {}).get("second_stage_bound") != "At most 2^8=256 reachable subsets."
            or workload.get("contract", {}).get("workspace_bytes") != 8192
            or inventory.get("contract", {}).get("maximum_parseable_input_length") != 10
            or inventory.get("contract", {}).get("maximum_result") != 256
            or inventory.get("contract", {}).get("workspace_bytes") != 8192
            or inventory.get("contract", {}).get("largest_fixed_table_payload_bytes") != 2616
            or inventory.get("contract", {}).get("mojo_list_entry_count") != 558
            or inventory.get("contract", {}).get("mojo_list_payload_bytes") != 4464):
        issues.append("bounded DFA or subset-stage values differ from the contract")
    return issues
