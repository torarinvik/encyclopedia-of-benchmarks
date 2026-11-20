"""Static workload consistency checks for the four-square package."""

import json
from pathlib import Path

from .independent_oracle import expected_result as independent_result
from .primary_oracle import expected_result as primary_result

PACKAGE = Path(__file__).resolve().parent


def workload_issues() -> list[str]:
    issues: list[str] = []
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("algorithm") != "four_square_sum_representation"
            or workload.get("function_symbol") != "four_square_sum_representation"
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("input", {}).get("maximum_valid_length") != 1
            or workload.get("input", {}).get("maximum_parseable_length") != 2):
        issues.append("workload metadata differs from the one-value bounded contract")
    seen: set[str] = set()
    for case in workload.get("cases", []):
        case_id = case.get("id")
        values = case.get("input_values")
        length = case.get("input_length")
        if not isinstance(case_id, str) or case_id in seen:
            issues.append("case identifiers are missing or duplicated")
            continue
        seen.add(case_id)
        is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int
                or (is_null and values) or (not is_null and length != len(values))):
            issues.append(f"{case_id}: malformed fixture frame")
            continue
        options = {"input_length": length, "input_is_null": is_null}
        primary = primary_result(values, **options)
        independent = independent_result(values, **options)
        if primary != independent or case.get("expected_result") != primary:
            issues.append(f"{case_id}: result differs between references or fixture")
    return issues
