"""Static fixture/reference reconciliation; not run while drafting."""

import json
from pathlib import Path

try:
    from .independent_oracle import expected_output as independent_expected
    from .primary_oracle import expected_output as primary_expected
except ImportError:
    from independent_oracle import expected_output as independent_expected
    from primary_oracle import expected_output as primary_expected

PACKAGE = Path(__file__).resolve().parent
REQUIRED_CASES = {
    "single_symbol", "equal_weights", "mixed_weights", "unequal_prefix_intervals",
    "maximum_input_and_output", "maximum_output_short_by_one", "invalid_zero_symbols",
    "invalid_zero_weight", "invalid_weight_above_bound", "trailing_word",
    "maximum_parseable_trailing_word", "invalid_before_output_error", "null_output", "null_input",
}


def workload_issues(workload: dict | None = None) -> list[str]:
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload: {error}"]
    issues: list[str] = []
    if (workload.get("schema_version") != 1
            or workload.get("id") != "shannon-fano-elias-symbol-codes-i64-array-bytes-output-v1"
            or workload.get("algorithm") != "shannon_fano_elias_symbol_codes"
            or workload.get("function_symbol") != "shannon_fano_elias_symbol_codes"
            or workload.get("abi") != "i64_array_bytes_output"):
        issues.append("workload identity or ABI differs from package contract")
    if (workload.get("input", {}).get("maximum_valid_length") != 9
            or workload.get("input", {}).get("maximum_parseable_length") != 10
            or workload.get("output", {}).get("maximum_bytes") != 17
            or workload.get("workspace", {}).get("bytes") != 1024
            or workload.get("contract", {}).get("maximum_symbols") != 8
            or workload.get("contract", {}).get("maximum_total_weight") != 120):
        issues.append("input, output, or workspace bounds differ from the bounded profile")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload must contain fixture cases"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict):
            issues.append("fixture entry must be an object")
            continue
        name = case.get("id")
        values = case.get("input_values")
        input_length = case.get("input_length")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        capacity = case.get("output_capacity")
        if (not isinstance(name, str) or not name or name in seen or not isinstance(values, list)
                or type(input_length) is not int or type(input_is_null) is not bool
                or type(output_is_null) is not bool or type(capacity) is not int or capacity < 0
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
                or (input_is_null and (values or input_length != 0))
                or (not input_is_null and input_length != len(values))
                or input_length > 10):
            issues.append(f"invalid fixture framing or ABI flags: {name!r}")
            continue
        seen.add(name)
        framed = None if input_is_null else values
        primary = primary_expected(framed, capacity, output_is_null, input_is_null, input_length)
        independent = independent_expected(framed, capacity, output_is_null, input_is_null, input_length)
        if primary != independent:
            issues.append(f"references disagree for {name}")
        if (case.get("expected_result") != primary[0]
                or case.get("expected_output_hex") != primary[1].hex()):
            issues.append(f"pinned result/output differs from references for {name}")
        if primary[0] >= 0 and len(primary[1]) != primary[0]:
            issues.append(f"successful output byte length differs for {name}")
        if primary[0] < 0 and primary[1] != b"":
            issues.append(f"error case must have no output bytes: {name}")
    if seen != REQUIRED_CASES:
        issues.append("workload fixture IDs differ from the statically reviewed set")
    return issues


def verify_workload() -> None:
    issues = workload_issues()
    if issues:
        raise ValueError("\n".join(issues))


if __name__ == "__main__":
    verify_workload()
