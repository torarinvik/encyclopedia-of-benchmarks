"""Static workload comparison for both DIET references."""

import json
from pathlib import Path

try:
    from . import independent_oracle, primary_oracle
except ImportError:
    import independent_oracle
    import primary_oracle


PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    issues = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]
    if workload.get("algorithm") != "discrete_interval_encoding_tree":
        issues.append("algorithm identifier mismatch")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("ABI mismatch")

    case_ids = set()
    for case in workload.get("cases", []):
        case_id = case.get("id", "<missing-id>")
        case_ids.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        capacity = case.get("output_capacity")
        output_null = case.get("output_is_null", False)
        input_null = case.get("input_is_null", False)
        if not isinstance(values, list) or type(length) is not int:
            issues.append(f"{case_id}: missing list input or input_length")
            continue
        if type(output_null) is not bool or type(input_null) is not bool:
            issues.append(f"{case_id}: null flags must be booleans")
            continue
        if not input_null and length != len(values):
            issues.append(f"{case_id}: non-null input length mismatch")
        if type(capacity) is not int or capacity < 0:
            issues.append(f"{case_id}: invalid output capacity")
            continue
        try:
            expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
        except (KeyError, TypeError, ValueError) as error:
            issues.append(f"{case_id}: invalid expected output: {error}")
            continue
        if expected[0] >= 0 and expected[0] != len(expected[1]):
            issues.append(f"{case_id}: successful result differs from output byte length")
        for label, reference in (("primary", primary_oracle.expected_output),
                                 ("independent", independent_oracle.expected_output)):
            try:
                actual = reference(values, capacity, output_null, input_null, length)
            except Exception as error:
                issues.append(f"{case_id}: {label} reference raised {error}")
                continue
            if actual != expected:
                issues.append(f"{case_id}: {label} reference disagrees with pinned output")

    required = {
        "bridge-two-runs-split-and-rejoin",
        "duplicate-insert-absent-delete",
        "maximum-frame-maximum-output",
        "maximum-output-one-byte-short",
        "maximum-parseable-trailing-word",
        "invalid-opcode-precedes-capacity",
        "null-input",
    }
    if not required <= case_ids:
        issues.append(f"missing required workload cases: {sorted(required - case_ids)}")
    return issues


def verify_workload() -> None:
    issues = workload_issues()
    if issues:
        raise ValueError("\n".join(issues))


if __name__ == "__main__":
    verify_workload()
