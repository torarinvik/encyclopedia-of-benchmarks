"""Static metadata, fixture, and source-inventory checks."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent
from .primary_oracle import (
    MAX_INPUT_LENGTH,
    MAX_N,
    MAX_RESULT,
    MAX_VALID_INPUT_LENGTH,
    expected_result as primary,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/p/powerful_number_summatory_sieve"
SYMBOL = "powerful_number_summatory_sieve"
SOURCE_URL = "https://oi-wiki.org/math/number-theory/powerful-number/"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED = {
    "unit-prefix", "first-prime-square", "prime-powers-and-products",
    "several-powerful-number-terms", "mixed-prime-power-terms", "null-input",
    "empty-frame", "zero-bound", "above-bound", "trailing-word",
}


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "p" / f"{SYMBOL}.{extension}"
        if not path.is_file():
            issues.append(f"missing language source: {language}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {language}")

    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload must be an object"]
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    profile = workload.get("algorithm_profile", {})
    source = workload.get("source", {})
    measurement = workload.get("measurement", {})
    if (workload.get("id") != "powerful-number-summatory-sieve-i64-array-scalar-v1"
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or source.get("url") != SOURCE_URL
            or source.get("example_url") != "https://atcoder.jp/contests/abc370/editorial/10882"
            or measurement.get("comparison_model") != "i64_array_scalar_call"
            or input_spec.get("kind") != "signed_64_bit_integer_array"
            or input_spec.get("encoding") != "[N]"
            or input_spec.get("n_range") != [1, MAX_N]
            or input_spec.get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_input_length") != MAX_INPUT_LENGTH
            or input_spec.get("invalid_input_result") != -1
            or profile.get("target_function") != "f(1)=1 and f is multiplicative with f(p^e)=p^(e-1), equivalently f(n)=n/rad(n)."
            or profile.get("convolution") != "Let g(n)=1 and h=mu*f. Then f=g*h, h(1)=1, h(p)=0, and h(p^e)=(p-1)*p^(e-2) for e>=2. The support of h consists exactly of powerful numbers."
            or profile.get("summatory_identity") != "Return sum(h(d)*floor(N/d)) over powerful d<=N; the d=1 term is N."
            or profile.get("enumeration") != "Sieve primes through floor(sqrt(N)); recursively choose increasing primes, each with exponent at least two, and accumulate every resulting powerful number exactly once."
            or profile.get("complexity") != "Prime sieve O(sqrt(N)*log(log(N))) time and O(sqrt(N)) storage; powerful-number enumeration visits O(sqrt(N)) products and accumulates each term in O(1)."
            or profile.get("result_bound") != "0<=F(N)<=N(N+1)/2<=500000500000, within signed 64-bit range."
            or output_spec.get("kind") != "signed_64_bit_integer"
            or output_spec.get("meaning") != "Exact sum of n/rad(n) for 1<=n<=N; -1 for invalid input."
            or output_spec.get("valid_result_range") != [0, MAX_RESULT]
            or output_spec.get("invalid_input_result") != -1):
        issues.append("workload identity, input framing, sieve profile, or output bounds differ")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing workload cases"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid workload case")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate workload case: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        expected = case.get("expected_result")
        input_is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int or length != len(values)
                or type(expected) is not int or type(input_is_null) is not bool):
            issues.append(f"invalid workload case fields: {case_id}")
            continue
        if primary(values, input_is_null, length) != expected:
            issues.append(f"primary-reference fixture mismatch: {case_id}")
        if independent(values, input_is_null, length) != expected:
            issues.append(f"independent-reference fixture mismatch: {case_id}")
    missing = REQUIRED - seen
    if missing:
        issues.append("missing required cases: " + ", ".join(sorted(missing)))
    return issues


static_issues = verify_workload
