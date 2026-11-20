"""Compare pinned workload fixtures with both independent IBLT references."""

import json
from pathlib import Path

try:
    from .independent_oracle import expected_output as independent_output
    from .primary_oracle import expected_output as primary_output
except ImportError:
    from independent_oracle import expected_output as independent_output
    from primary_oracle import expected_output as primary_output


PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    """Return fixture/reference disagreements without raising on a mismatch."""
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        cases = workload["cases"]
    except (OSError, json.JSONDecodeError, KeyError, TypeError) as error:
        return [f"cannot read package workload: {error}"]

    issues: list[str] = []
    for case in cases:
        case_id = case.get("id", "<missing-id>")
        try:
            values = case["input_values"]
            length = case["input_length"]
            capacity = case["output_capacity"]
            expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
            output_is_null = case.get("output_is_null", False)
            input_is_null = case.get("input_is_null", False)
        except (KeyError, TypeError, ValueError) as error:
            issues.append(f"malformed workload fixture {case_id}: {error}")
            continue

        for label, reference in (("primary", primary_output), ("independent", independent_output)):
            try:
                actual = reference(values, capacity, output_is_null, input_is_null, length)
            except Exception as error:  # Surface fixture/reference boundary failures to callers.
                issues.append(f"{label} reference failed for {case_id}: {error}")
                continue
            if actual != expected:
                issues.append(f"{label} reference disagrees with fixture {case_id}")
    return issues


def verify_workload() -> None:
    issues = workload_issues()
    if issues:
        raise ValueError("\n".join(issues))


if __name__ == "__main__":
    verify_workload()
