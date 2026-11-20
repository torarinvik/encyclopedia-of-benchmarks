"""Static source inventory and workload checks for composite k | n!."""

from __future__ import annotations

import json
from pathlib import Path

from .independent_oracle import expected_result as independent
from .primary_oracle import expected_result as primary

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/f/factorial_divisor_composite_k"
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
SYMBOL = "factorial_divisor_composite_k"


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    required_files = (
        "README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
        "independent_oracle.py",
    )
    for name in required_files:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, extension in EXTENSIONS.items():
        source = ROOT / language / "f" / f"{SYMBOL}.{extension}"
        if not source.is_file():
            issues.append(f"missing language source: {language}")
        elif SYMBOL not in source.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {language}")

    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload must be an object"]
    input_contract = workload.get("input", {})
    measurement = workload.get("measurement", {})
    source = workload.get("source", {})
    output = workload.get("output", {})
    if not all(isinstance(value, dict)
               for value in (input_contract, measurement, source, output)):
        return issues + ["workload input, measurement, source, and output must be objects"]
    if (workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "binary_scalar"
            or input_contract.get("n_range") != [0, 1_000_000_000_000]
            or input_contract.get("composite_k_range") != [4, 1_000_000]
            or input_contract.get("k_must_be_composite") is not True
            or measurement.get("comparison_model") != "binary_scalar_call"
            or source.get("url") != "https://cp-algorithms.com/algebra/factorial-divisors.html#composite-k"
            or output.get("encoding") != "largest x such that k^x divides n!"):
        issues.append("workload identity, ABI, or bounds differ from the contract")

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
        expected = case.get("expected_result")
        if (not isinstance(values, list) or len(values) != 2
                or any(type(value) is not int or not 0 <= value <= (1 << 64) - 1
                       for value in values)
                or type(expected) is not int
                or primary(*values) != expected
                or independent(*values) != expected):
            issues.append(f"fixture/reference mismatch: {case_id}")
    required_cases = {
        "empty-factorial", "prime-power-divisor", "two-prime-divisor",
        "several-prime-factors", "maximum-n-prime-power", "maximum-k",
        "prime-k-small", "n-above-maximum",
    }
    if not required_cases <= seen:
        issues.append("missing required cases: " + ", ".join(sorted(required_cases - seen)))
    return issues


static_issues = verify_workload
