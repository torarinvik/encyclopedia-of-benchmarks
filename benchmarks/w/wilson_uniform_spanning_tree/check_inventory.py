"""Static package metadata and framing checker; not run during drafting."""

import json
from pathlib import Path


PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
EXPECTED_SOURCES = {
    f"{language}/w/wilson_uniform_spanning_tree.{extension}"
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

    if inventory.get("algorithm") != "wilson_uniform_spanning_tree":
        issues.append("inventory algorithm ID differs")
    if inventory.get("abi") != "i64_array_bytes_output":
        issues.append("inventory ABI differs")
    if set(inventory.get("sources", [])) != EXPECTED_SOURCES:
        issues.append("inventory does not list exactly the ten language ports")
    for relative in EXPECTED_SOURCES:
        if not (ROOT / relative).is_file():
            issues.append(f"missing source: {relative}")
    for relative in inventory.get("references", []) + inventory.get("artifacts", []):
        if not (PACKAGE / relative).is_file():
            issues.append(f"missing package artifact: {relative}")

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
            issues.append(f"fixture result/output byte count differs: {case_id}")
        if result < 0 and output_size:
            issues.append(f"error fixture has nonempty output: {case_id}")
        if output_size > inventory.get("maximum_output_bytes", 0):
            issues.append(f"fixture output exceeds bound: {case_id}")

    cap_case = cases.get("walk_exceeds_64_step_cap", {})
    cap_values = cap_case.get("input_values", [])
    if len(cap_values) >= 10:
        cap_q_at = 3 + 2 * cap_values[1]
        if (cap_values[cap_q_at] != 64 or len(cap_values) != cap_q_at + 65
                or any(value != 1 for value in cap_values[cap_q_at + 1:])):
            issues.append("64-step cap fixture does not contain exactly 64 rank-one draws")
    else:
        issues.append("64-step cap fixture is missing or truncated")

    singleton = cases.get("one_vertex_empty_output_accepts_null", {})
    if (singleton.get("expected_result") != 0 or singleton.get("expected_output_hex") != ""
            or not singleton.get("output_is_null")):
        issues.append("n=1 empty-output fixture does not pin null-output success")
    maximum = cases.get("maximum_output_eight_vertex_star", {})
    short = cases.get("maximum_output_one_byte_short", {})
    if maximum.get("expected_result") != 112 or short.get("output_capacity") != 111 or short.get("expected_result") != -2:
        issues.append("maximum-output and one-byte-short fixtures differ from bounds")

    verifier = (PACKAGE / "verify_workload.py").read_text(encoding="utf-8")
    if "def workload_issues() -> list[str]:" not in verifier:
        issues.append("workload verifier does not expose workload_issues()")
    if "from .primary_oracle import" not in verifier or "from .independent_oracle import" not in verifier:
        issues.append("workload verifier is missing package-relative imports")
    return issues
