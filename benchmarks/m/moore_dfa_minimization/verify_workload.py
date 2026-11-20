"""Static workload/reference reconciliation; not executed during drafting."""

import json
from pathlib import Path

try:
    from .independent_oracle import expected as independent_expected
    from .primary_oracle import expected as primary_expected
except ImportError:
    from independent_oracle import expected as independent_expected
    from primary_oracle import expected as primary_expected

PACKAGE = Path(__file__).resolve().parent
REQUIRED_CASES = {
    "one_rejecting_state", "one_accepting_state", "two_initial_classes",
    "one_refinement_round", "two_refinement_rounds", "unreachable_accepting_state_retained",
    "maximum_input_frame", "maximum_overlong_frame", "invalid_n", "invalid_start",
    "invalid_transition", "trailing_word", "null_input",
}


def workload_issues(workload: dict | None = None) -> list[str]:
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    issues: list[str] = []
    if (workload.get("schema_version") != 1 or workload.get("id") != "moore-dfa-minimization-v1"
            or workload.get("algorithm") != "moore_dfa_minimization"
            or workload.get("function_symbol") != "moore_dfa_minimization"
            or workload.get("input", {}).get("kind") != "i64_array_scalar"):
        issues.append("workload identity or ABI differs from package contract")
    inp = workload.get("input", {})
    contract = workload.get("contract", {})
    if (inp.get("maximum_states") != 8 or inp.get("maximum_alphabet") != 3
            or inp.get("maximum_valid_length") != 28 or inp.get("maximum_parseable_length") != 29
            or workload.get("workspace", {}).get("bytes") != 4096
            or contract.get("maximum_workspace_bytes") != 4096
            or contract.get("all_states_participate") is not True
            or contract.get("unreachable_states_removed") is not False):
        issues.append("input, reachability, or workspace bounds differ from contract")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload must contain fixture cases"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict):
            issues.append("fixture entry must be an object")
            continue
        name, values = case.get("id"), case.get("input_values")
        null = case.get("input_is_null", False)
        length = case.get("input_length")
        if (not isinstance(name, str) or not name or name in seen or not isinstance(values, list)
                or len(values) > 29 or type(null) is not bool or type(length) is not int
                or not 0 <= length <= 29 or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
                or (null and (values or length != 0)) or (not null and length != len(values))):
            issues.append(f"invalid fixture framing: {name!r}")
            continue
        seen.add(name)
        framed_values = None if null else values
        actual_primary = primary_expected(framed_values)
        actual_independent = independent_expected(framed_values)
        if actual_primary != actual_independent:
            issues.append(f"references disagree for {name}")
        if case.get("expected_result") != actual_primary:
            issues.append(f"pinned result differs from references for {name}")
    if seen != REQUIRED_CASES:
        issues.append("workload fixture IDs differ from the statically reviewed set")
    return issues


def verify_workload() -> None:
    issues = workload_issues()
    if issues:
        raise ValueError("\n".join(issues))


if __name__ == "__main__":
    verify_workload()
