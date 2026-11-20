"""Static package and workload metadata checker; not run during drafting."""

import json
from pathlib import Path


PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
EXPECTED_SOURCES = {
    f"{language}/m/multiply_shift_universal_hash_trace.{extension}"
    for language, extension in (
        ("c", "c"), ("c3", "c3"), ("cpp", "cpp"), ("elisa", "elisa"),
        ("mojo", "mojo"), ("nim", "nim"), ("odin", "odin"),
        ("rust", "rs"), ("v", "v"), ("zig", "zig"),
    )
}


def static_issues() -> list[str]:
    issues = []
    inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if inventory.get("algorithm") != "multiply_shift_universal_hash_trace":
        issues.append("inventory algorithm ID differs")
    if inventory.get("abi") != "i64_array_bytes_output":
        issues.append("inventory ABI differs")
    if set(inventory.get("sources", [])) != EXPECTED_SOURCES:
        issues.append("inventory source list is not the ten expected language paths")
    for relative in EXPECTED_SOURCES:
        if not (ROOT / relative).is_file():
            issues.append(f"missing source: {relative}")
    for relative in inventory.get("references", []) + inventory.get("artifacts", []):
        if not (PACKAGE / relative).is_file():
            issues.append(f"missing package artifact: {relative}")
    verifier = (PACKAGE / "verify_workload.py").read_text(encoding="utf-8")
    if "def workload_issues() -> list[str]:" not in verifier:
        issues.append("workload verifier does not expose workload_issues()")
    if "from .independent_oracle import" not in verifier or "from .primary_oracle import" not in verifier:
        issues.append("workload verifier is missing package-relative oracle imports")
    if workload.get("algorithm") != inventory.get("algorithm"):
        issues.append("workload and inventory algorithm IDs differ")
    bounds = workload.get("input", {})
    output = workload.get("output", {})
    if bounds.get("maximum_valid_length") != inventory.get("maximum_valid_input_words"):
        issues.append("maximum valid input bound differs")
    if bounds.get("maximum_parseable_length") != inventory.get("maximum_parseable_input_words"):
        issues.append("maximum parseable input bound differs")
    if output.get("maximum_output_bytes") != inventory.get("maximum_output_bytes"):
        issues.append("maximum output bound differs")
    if workload.get("workspace", {}).get("bytes") != inventory.get("workspace_bytes"):
        issues.append("workspace bound differs")
    for case in workload.get("cases", []):
        values = case.get("input_values")
        if not isinstance(values, list) or len(values) != case.get("input_length"):
            issues.append(f"fixture input framing differs: {case.get('id')}")
        encoded = case.get("expected_output_hex", "")
        if len(encoded) % 2:
            issues.append(f"fixture output hex has an odd digit count: {case.get('id')}")
        result = case.get("expected_result", -1)
        if result >= 0 and len(encoded) // 2 != result:
            issues.append(f"fixture output byte count differs: {case.get('id')}")
        if result < 0 and encoded:
            issues.append(f"error fixture must leave output empty: {case.get('id')}")
        if result > inventory.get("maximum_output_bytes", 0):
            issues.append(f"fixture output exceeds bound: {case.get('id')}")
    return issues
