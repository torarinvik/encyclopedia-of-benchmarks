"""Static package and reference-fixture checks."""

import json
from pathlib import Path

from c.cipolla_modular_square_root.independent_oracle import expected_result as independent
from c.cipolla_modular_square_root.primary_oracle import expected_result as primary

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/c/cipolla_modular_square_root"
EXTENSIONS = {"c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
              "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
              "v": "v", "zig": "zig"}
SYMBOL = "cipolla_modular_square_root"


def verify_workload(workload=None) -> list[str]:
    issues = []
    for name in ("README.md", "RIGHTS.md", "workload.json",
                 "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, extension in EXTENSIONS.items():
        source = ROOT / language / "c" / f"{SYMBOL}.{extension}"
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
    if (workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("input", {}).get("maximum_valid_input_length") != 2
            or workload.get("input", {}).get("maximum_parseable_input_length") != 3
            or workload.get("input", {}).get("prime_must_be_prime") is not True
            or workload.get("workspace", {}).get("bytes") != 256
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"):
        issues.append("workload identity, ABI limits, or workspace budget differ from the contract")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing workload cases"]
    seen = set()
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
        if (not isinstance(values, list) or type(expected) is not int
                or primary(values) != expected or independent(values) != expected):
            issues.append(f"fixture/reference mismatch: {case_id}")
    required = {"textbook-small-residue", "zero-residue", "nonresidue",
                "large-prime-small-root", "trailing-input-word"}
    if not required <= seen:
        issues.append("missing required cases: " + ", ".join(sorted(required - seen)))
    return issues


static_issues = verify_workload
