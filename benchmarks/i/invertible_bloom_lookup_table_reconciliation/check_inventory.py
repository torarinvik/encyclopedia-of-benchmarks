"""Static package and workload metadata checker; not run during drafting."""

import json
from pathlib import Path


PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
EXPECTED_SOURCES = {
    f"{language}/i/invertible_bloom_lookup_table_reconciliation.{extension}"
    for language, extension in (
        ("c", "c"), ("c3", "c3"), ("cpp", "cpp"), ("elisa", "elisa"),
        ("mojo", "mojo"), ("nim", "nim"), ("odin", "odin"),
        ("rust", "rs"), ("v", "v"), ("zig", "zig"),
    )
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package metadata: {error}"]

    if inventory.get("algorithm") != "invertible_bloom_lookup_table_reconciliation":
        issues.append("inventory algorithm ID differs")
    if inventory.get("abi") != "i64_array_bytes_output":
        issues.append("inventory ABI differs")
    if set(inventory.get("sources", [])) != EXPECTED_SOURCES:
        issues.append("inventory does not list exactly the ten language ports")
    for source in EXPECTED_SOURCES:
        if not (ROOT / source).is_file():
            issues.append(f"missing source: {source}")
    for artifact in inventory.get("references", []) + inventory.get("artifacts", []):
        if not (PACKAGE / artifact).is_file():
            issues.append(f"missing package artifact: {artifact}")
    if workload.get("algorithm") != inventory.get("algorithm"):
        issues.append("workload and inventory algorithm IDs differ")
    input_bounds = workload.get("input", {})
    output_bounds = workload.get("output", {})
    if input_bounds.get("maximum_valid_length") != inventory.get("maximum_valid_input_words"):
        issues.append("maximum valid input bound differs")
    if input_bounds.get("maximum_parseable_length") != inventory.get("maximum_parseable_input_words"):
        issues.append("maximum parseable input bound differs")
    if output_bounds.get("maximum_output_bytes") != inventory.get("maximum_output_bytes"):
        issues.append("maximum output bound differs")
    if workload.get("workspace", {}).get("bytes") != inventory.get("workspace_bytes"):
        issues.append("workspace bound differs")

    cases = {case.get("id"): case for case in workload.get("cases", [])}
    for case in workload.get("cases", []):
        case_id = case.get("id", "<missing-id>")
        values = case.get("input_values")
        if not isinstance(values, list) or len(values) != case.get("input_length"):
            issues.append(f"fixture input framing differs: {case_id}")
        encoded = case.get("expected_output_hex", "")
        if not isinstance(encoded, str) or len(encoded) % 2:
            issues.append(f"fixture output hex is malformed: {case_id}")
            continue
        try:
            output_size = len(bytes.fromhex(encoded))
        except ValueError:
            issues.append(f"fixture output hex is malformed: {case_id}")
            continue
        result = case.get("expected_result")
        if result >= 0 and output_size != result:
            issues.append(f"fixture result/output size differs: {case_id}")
        if result < 0 and output_size:
            issues.append(f"error fixture has nonempty output: {case_id}")
        if output_size > inventory.get("maximum_output_bytes", 0):
            issues.append(f"fixture output exceeds maximum: {case_id}")

    incomplete = cases.get("colliding-triples-leave-incomplete-core", {})
    if incomplete.get("expected_output_hex") != "000000000000000000000000000000000000000000000000":
        issues.append("incomplete-core fixture no longer pins [0,0,0]")
    capacity_case = cases.get("max-output-capacity-one-byte-short", {})
    if capacity_case.get("output_capacity") != 151 or capacity_case.get("expected_result") != -2:
        issues.append("maximum-output short-capacity fixture differs")

    verifier = (PACKAGE / "verify_workload.py").read_text(encoding="utf-8")
    if "def workload_issues() -> list[str]:" not in verifier:
        issues.append("workload verifier does not expose workload_issues()")
    if "from .primary_oracle import" not in verifier or "from .independent_oracle import" not in verifier:
        issues.append("workload verifier is missing package-relative oracle imports")
    return issues
