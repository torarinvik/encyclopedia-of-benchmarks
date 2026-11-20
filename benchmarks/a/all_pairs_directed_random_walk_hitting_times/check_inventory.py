"""Static package metadata and source-path checks."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks" / "a" / "all_pairs_directed_random_walk_hitting_times"
LANGUAGES = {
    "c": "c/a/all_pairs_directed_random_walk_hitting_times.c",
    "c3": "c3/a/all_pairs_directed_random_walk_hitting_times.c3",
    "cpp": "cpp/a/all_pairs_directed_random_walk_hitting_times.cpp",
    "elisa": "elisa/a/all_pairs_directed_random_walk_hitting_times.elisa",
    "mojo": "mojo/a/all_pairs_directed_random_walk_hitting_times.mojo",
    "nim": "nim/a/all_pairs_directed_random_walk_hitting_times.nim",
    "odin": "odin/a/all_pairs_directed_random_walk_hitting_times.odin",
    "rust": "rust/a/all_pairs_directed_random_walk_hitting_times.rs",
    "v": "v/a/all_pairs_directed_random_walk_hitting_times.v",
    "zig": "zig/a/all_pairs_directed_random_walk_hitting_times.zig",
}


def static_issues():
    issues = []
    inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if inventory.get("algorithm") != "all_pairs_directed_random_walk_hitting_times":
        issues.append("inventory algorithm name mismatch")
    if inventory.get("abi") != "i64_array_bytes_output":
        issues.append("inventory ABI mismatch")
    if inventory.get("sources") != list(LANGUAGES.values()):
        issues.append("inventory source paths differ from the ten language paths")
    bounds = inventory.get("bounds", {})
    if (bounds.get("maximum_valid_input_words") != 114
            or bounds.get("maximum_parseable_input_words") != 115
            or bounds.get("maximum_output_bytes") != 512
            or bounds.get("workspace_bytes") != 8192):
        issues.append("inventory bounds differ from the pinned contract")
    for language, relative in LANGUAGES.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} source: {relative}")
        else:
            source = path.read_text(encoding="utf-8")
            if "all_pairs_directed_random_walk_hitting_times" not in source:
                issues.append(f"{language} source omits exported symbol: {relative}")
            if relative not in (PACKAGE / "README.md").read_text(encoding="utf-8"):
                issues.append(f"README omits {language} source path: {relative}")
    for artifact in inventory.get("artifacts", []):
        if not (ROOT / artifact).is_file():
            issues.append(f"missing package artifact: {artifact}")
    if workload.get("function_symbol") != "all_pairs_directed_random_walk_hitting_times":
        issues.append("workload function symbol mismatch")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("workload ABI mismatch")
    if workload.get("input", {}).get("maximum_valid_length") != 114:
        issues.append("valid input bound mismatch")
    if workload.get("input", {}).get("maximum_parseable_length") != 115:
        issues.append("parseable input bound mismatch")
    if workload.get("output", {}).get("maximum_bytes") != 512:
        issues.append("output bound mismatch")
    if workload.get("workspace", {}).get("bytes") != 8192:
        issues.append("workspace bound mismatch")
    profile = workload.get("generated_profile", {})
    if (profile.get("maximum_n") != 8
            or profile.get("maximum_valid_input_length") != 114
            or profile.get("maximum_parseable_input_length") != 115
            or profile.get("maximum_output_bytes") != 512):
        issues.append("generated profile bounds mismatch")
    for case in workload.get("cases", []):
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"{case.get('id')}: input framing mismatch")
        if (type(case.get("input_is_null", False)) is not bool
                or type(case.get("output_is_null", False)) is not bool):
            issues.append(f"{case.get('id')}: null flags must be booleans")
        if case.get("input_is_null", False) and (values or case.get("input_length") != 0):
            issues.append(f"{case.get('id')}: null input must have an empty zero-length frame")
        try:
            payload = bytes.fromhex(case.get("expected_output_hex", ""))
        except (TypeError, ValueError):
            issues.append(f"{case.get('id')}: invalid output hex")
            continue
        result = case.get("expected_result")
        if type(result) is not int:
            issues.append(f"{case.get('id')}: expected result is not an integer")
        elif result >= 0 and result != len(payload):
            issues.append(f"{case.get('id')}: successful byte count differs from payload")
        elif result < 0 and payload:
            issues.append(f"{case.get('id')}: error fixture must not write output")
        if result >= 0 and isinstance(values, list) and len(values) >= 2:
            n, m = values[0], values[1]
            if type(n) is int and type(m) is int and result != 8 * n * n:
                issues.append(f"{case.get('id')}: success bytes do not match n*n matrix size")
        if case.get("id") == "maximum-parseable-trailing-word":
            if (case.get("input_length") != 115 or len(values) != 115
                    or result != -1 or payload):
                issues.append("maximum parseable frame must be the 115-word invalid trailing case")
    if not any(case.get("id") == "maximum-parseable-trailing-word"
               for case in workload.get("cases", [])):
        issues.append("workload omits the maximum parseable input frame")
    return issues
