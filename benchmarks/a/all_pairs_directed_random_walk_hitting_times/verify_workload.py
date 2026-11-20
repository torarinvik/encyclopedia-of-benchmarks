"""Static workload-to-reference reconciliation; never runs native programs."""

import json
from pathlib import Path

try:
    from . import independent_oracle, primary_oracle
    from .check_inventory import LANGUAGES, static_issues
except ImportError:
    import independent_oracle
    import primary_oracle
    from check_inventory import LANGUAGES, static_issues

PACKAGE = Path(__file__).resolve().parent


def workload_issues():
    issues = list(static_issues())
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (primary_oracle.MAX_VALID_INPUT_LENGTH != 114
            or primary_oracle.MAX_PARSEABLE_INPUT_LENGTH != 115
            or primary_oracle.MAX_OUTPUT_BYTES != 512
            or primary_oracle.WORKSPACE_BYTES != 8192
            or independent_oracle.MAX_PARSEABLE_INPUT_LENGTH != 115
            or independent_oracle.MAX_OUTPUT_BYTES != 512
            or independent_oracle.WORKSPACE_BYTES != 8192):
        issues.append("reference constants differ from the workload bounds")
    if workload.get("source", {}).get("method_reference") != "https://oi-wiki.org/graph/graph-random-walk/":
        issues.append("primary source provenance mismatch")
    if workload.get("contract", {}).get("input_layout") != "[n,m,(u,v)*m]":
        issues.append("input layout mismatch")
    cases = workload.get("cases", [])
    seen = set()
    for case in cases:
        case_id = case.get("id")
        if not isinstance(case_id, str) or case_id in seen:
            issues.append(f"invalid or duplicate case ID: {case_id}")
            continue
        seen.add(case_id)
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"{case_id}: declared frame differs from values")
            continue
        args = (values, case.get("output_capacity"), case.get("output_is_null", False),
                case.get("input_is_null", False), case.get("input_length"))
        expected_hex = case.get("expected_output_hex", "")
        try:
            pinned = (case.get("expected_result"), bytes.fromhex(expected_hex))
        except (TypeError, ValueError):
            issues.append(f"{case_id}: malformed pinned output")
            continue
        primary = primary_oracle.expected_output(
            values, output_capacity=args[1], output_is_null=args[2],
            input_is_null=args[3], input_length=args[4])
        independent = independent_oracle.expected_output(
            values, output_capacity=args[1], output_is_null=args[2],
            input_is_null=args[3], input_length=args[4])
        if primary != independent:
            issues.append(f"{case_id}: references disagree")
        if primary != pinned:
            issues.append(f"{case_id}: primary result differs from fixture")
        if independent != pinned:
            issues.append(f"{case_id}: independent result differs from fixture")
    required = {
        "directed-three-cycle", "complete-directed-three-vertex-graph",
        "asymmetric-chord-with-fractional-hitting-time", "maximum-output-short-by-one",
        "maximum-frame-complete-digraph", "maximum-frame-one-byte-short",
        "maximum-parseable-trailing-word",
        "not-strongly-connected", "duplicate-directed-arc", "self-loop",
        "trailing-word-frame", "malformed-before-output-capacity",
        "short-output-capacity", "null-output", "null-input",
    }
    if required - seen:
        issues.append(f"missing workload cases: {sorted(required - seen)}")
    by_id = {case.get("id"): case for case in cases if isinstance(case, dict)}
    maximum_valid = by_id.get("maximum-frame-complete-digraph", {}).get("input_values")
    maximum_parseable = by_id.get("maximum-parseable-trailing-word", {}).get("input_values")
    if (not isinstance(maximum_valid, list) or not isinstance(maximum_parseable, list)
            or maximum_parseable[:-1] != maximum_valid or maximum_parseable[-1] != 99):
        issues.append("maximum parseable fixture must append one word to the maximum valid frame")
    for relative in LANGUAGES.values():
        if relative not in (PACKAGE / "README.md").read_text(encoding="utf-8"):
            issues.append(f"README omits source path: {relative}")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if "No upstream implementation" not in rights:
        issues.append("rights note omits clean-room statement")
    return issues
