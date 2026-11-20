"""Static artifact and workload-metadata inventory for the DIET package."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks" / "d" / "discrete_interval_encoding_tree"
SOURCES = [
    "c/d/discrete_interval_encoding_tree.c",
    "c3/d/discrete_interval_encoding_tree.c3",
    "cpp/d/discrete_interval_encoding_tree.cpp",
    "elisa/d/discrete_interval_encoding_tree.elisa",
    "mojo/d/discrete_interval_encoding_tree.mojo",
    "nim/d/discrete_interval_encoding_tree.nim",
    "odin/d/discrete_interval_encoding_tree.odin",
    "rust/d/discrete_interval_encoding_tree.rs",
    "v/d/discrete_interval_encoding_tree.v",
    "zig/d/discrete_interval_encoding_tree.zig",
]


def static_issues() -> list[str]:
    issues = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package metadata: {error}"]
    if inventory.get("sources") != SOURCES:
        issues.append("INVENTORY.json language source list mismatch")
    for path in SOURCES:
        if not (ROOT / path).is_file():
            issues.append(f"missing language source {path}")
    for artifact in inventory.get("artifacts", []):
        if not (ROOT / artifact).is_file():
            issues.append(f"missing package artifact {artifact}")
    if workload.get("function_symbol") != inventory.get("function_symbol"):
        issues.append("function symbol differs between workload and inventory")
    if workload.get("abi") != inventory.get("abi"):
        issues.append("ABI differs between workload and inventory")
    bounds = inventory.get("bounds", {})
    input_meta = workload.get("input", {})
    output_meta = workload.get("output", {})
    if input_meta.get("maximum_valid_length") != bounds.get("maximum_valid_input_words"):
        issues.append("maximum valid input bound mismatch")
    if input_meta.get("maximum_parseable_length") != bounds.get("maximum_parseable_input_words"):
        issues.append("maximum parseable input bound mismatch")
    if output_meta.get("maximum_output_bytes") != bounds.get("maximum_output_bytes"):
        issues.append("maximum output bound mismatch")
    if workload.get("workspace", {}).get("bytes") != bounds.get("workspace_bytes"):
        issues.append("workspace bound mismatch")
    found_max = False
    found_trailing = False
    found_short_capacity = False
    for case in workload.get("cases", []):
        if case.get("id") == "maximum-frame-maximum-output":
            found_max = (case.get("input_length") == 65 and
                         len(case.get("input_values", [])) == 65 and
                         case.get("expected_result") == 256)
        elif case.get("id") == "maximum-parseable-trailing-word":
            found_trailing = (case.get("input_length") == 66 and
                              len(case.get("input_values", [])) == 66 and
                              case.get("expected_result") == -1)
        elif case.get("id") == "maximum-output-one-byte-short":
            found_short_capacity = (case.get("output_capacity") == 255 and
                                     case.get("expected_result") == -2)
    if not found_max:
        issues.append("maximum input/output fixture missing or incorrect")
    if not found_trailing:
        issues.append("maximum parseable trailing-word fixture missing or incorrect")
    if not found_short_capacity:
        issues.append("maximum-output one-byte-short fixture missing or incorrect")
    return issues


def check_inventory() -> None:
    issues = static_issues()
    if issues:
        raise ValueError("\n".join(issues))


if __name__ == "__main__":
    check_inventory()
