"""Static fixture/reference review; never launches compiled benchmark programs."""

from __future__ import annotations

import json
from pathlib import Path

from .check_inventory import static_issues
from .independent_oracle import expected_result as independent_expected
from .primary_oracle import expected_result as primary_expected

PACKAGE = Path(__file__).resolve().parent
REQUIRED_CASES = {
    "even-self-loop", "odd-self-loop", "minimum-even-versus-maximum-even-convention",
    "opponent-owned-all-successors-enter-attractor", "second-recursive-attractor-branch",
    "maximum-valid-frame", "trailing-word", "missing-outgoing-edge", "invalid-owner",
    "invalid-priority", "duplicate-arc", "out-of-range-endpoint",
}


def verify_workload() -> list[str]:
    issues = static_issues()
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read workload: {error}"]
    if workload.get("algorithm") != "zielonka_parity_game_solver":
        issues.append("workload algorithm does not match the package")
    if workload.get("function_symbol") != "zielonka_parity_game_solver":
        issues.append("workload function symbol does not match the package")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("workload ABI is not i64_array_scalar")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload has no fixture list"]
    identifiers: set[str] = set()
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object fixture")
            continue
        case_id = case.get("id")
        values = case.get("input_values")
        if not isinstance(case_id, str) or case_id in identifiers:
            issues.append("fixture IDs must be unique strings")
            continue
        identifiers.add(case_id)
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"fixture {case_id} has inconsistent framing")
            continue
        primary = primary_expected(values)
        independent = independent_expected(values)
        if primary != independent:
            issues.append(f"fixture {case_id} differs between the recursive and strategy references")
        if case.get("expected_result") != primary:
            issues.append(f"fixture {case_id} has an incorrect documented result")
    if identifiers != REQUIRED_CASES:
        issues.append("workload does not include the complete named fixture set")
    return issues
