"""Static fixture and reference comparison; never launches benchmark programs."""

from __future__ import annotations

import json
from pathlib import Path

from .check_inventory import static_issues
from .independent_oracle import expected_result as independent_expected
from .primary_oracle import (
    MAX_N,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    MODULUS,
    WORKSPACE_BYTES,
    expected_result as primary_expected,
)

PACKAGE = Path(__file__).resolve().parent
REQUIRED_CASES = {
    "f_one_only", "prime_power_exponents_through_two", "mixed_through_three",
    "prime_power_exponents_through_four",
    "mixed_prime_powers_through_six", "radical_through_ten", "prime_power_exponents_through_ten",
    "maximum_input_zero_function", "maximum_coefficients_at_one", "empty_input",
    "wrong_input_length", "parseable_extra_value", "zero_n", "n_above_local_bound",
    "negative_a", "negative_b", "a_not_canonical", "b_not_canonical",
}


def verify_workload() -> list[str]:
    issues = static_issues()
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read workload: {error}"]
    if (workload.get("algorithm") != "zhouge_summatory_multiplicative_function"
            or workload.get("function_symbol") != "zhouge_summatory_multiplicative_function"
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES):
        issues.append("workload algorithm, ABI, or workspace differs from the package contract")
    input_spec = workload.get("input", {})
    if (input_spec.get("layout") != "[N, a, b]"
            or input_spec.get("minimum_n") != 1
            or input_spec.get("maximum_n") != MAX_N
            or input_spec.get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_input_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_spec.get("coefficient_modulus") != MODULUS
            or input_spec.get("coefficient_range") != f"0 <= a,b < {MODULUS}"
            or input_spec.get("prime_power_definition") != "f(p^e) = a*e + b*p mod 469762049"):
        issues.append("workload input bounds differ from the bounded prime-power contract")
    output_spec = workload.get("output", {})
    if (output_spec.get("kind") != "signed_64_bit_integer"
            or output_spec.get("modulus") != MODULUS
            or output_spec.get("invalid_input_result") != -1):
        issues.append("workload output differs from the scalar modular contract")
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
            issues.append(f"fixture {case_id} differs between Zhouge and direct-factorization references")
        if case.get("expected_result") != primary:
            issues.append(f"fixture {case_id} has an incorrect documented result")
    if identifiers != REQUIRED_CASES:
        issues.append("workload does not include the complete named fixture set")
    measurement = workload.get("measurement", {})
    if (measurement.get("comparison_model") != "i64_array_scalar_call"
            or measurement.get("sample_count") != 7
            or measurement.get("warmup_rounds") != 1
            or measurement.get("repetitions_per_sample") != 1):
        issues.append("workload measurement settings differ from the scalar suite contract")
    return issues
