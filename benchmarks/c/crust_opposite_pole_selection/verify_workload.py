"""Static fixture/reference review; never launches compiled benchmark programs."""

from __future__ import annotations

import json
from pathlib import Path

from .check_inventory import static_issues
from .independent_oracle import expected_output as independent_expected
from .primary_oracle import expected_output as primary_expected

PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    issues = static_issues()
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read workload: {error}"]
    if workload.get("algorithm") != "crust_opposite_pole_selection":
        issues.append("workload algorithm does not match the package")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("workload ABI does not match the package")
    seen: set[str] = set()
    for group in ("cases", "invalid_cases", "capacity_cases"):
        cases = workload.get(group)
        if not isinstance(cases, list) or not cases:
            issues.append(f"workload has no {group}")
            continue
        for case in cases:
            if not isinstance(case, dict):
                issues.append(f"{group} contains a non-object case")
                continue
            case_id = case.get("id")
            values = case.get("input_values")
            if not isinstance(case_id, str) or case_id in seen:
                issues.append("workload case IDs must be unique strings")
                continue
            seen.add(case_id)
            if not isinstance(values, list) or case.get("input_length") != len(values):
                issues.append(f"case {case_id} has inconsistent input framing")
                continue
            args = {
                "capacity": case.get("output_capacity"),
                "output_is_null": case.get("output_is_null", False),
                "input_is_null": case.get("input_is_null", False),
                "input_length": case.get("input_length"),
            }
            primary = primary_expected(values, **args)
            independent = independent_expected(values, **args)
            if primary != independent:
                issues.append(f"case {case_id} differs between the two references")
            if case.get("expected_result") != primary[0]:
                issues.append(f"case {case_id} has an incorrect expected result")
            expected_hex = case.get("expected_output_hex")
            if expected_hex is not None:
                try:
                    expected_bytes = bytes.fromhex(expected_hex)
                except (TypeError, ValueError):
                    issues.append(f"case {case_id} has malformed expected output hex")
                else:
                    if expected_bytes != primary[1]:
                        issues.append(f"case {case_id} has an incorrect expected output")
            elif group == "cases":
                issues.append(f"valid case {case_id} is missing expected output hex")
    return issues
