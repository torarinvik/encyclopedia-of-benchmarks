"""Static package checks for the bounded Library Checker profile."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": ROOT / "c/n/number_of_increasing_sequences_between_two_sequences.c",
    "c3": ROOT / "c3/n/number_of_increasing_sequences_between_two_sequences.c3",
    "cpp": ROOT / "cpp/n/number_of_increasing_sequences_between_two_sequences.cpp",
    "elisa": ROOT / "elisa/n/number_of_increasing_sequences_between_two_sequences.elisa",
    "mojo": ROOT / "mojo/n/number_of_increasing_sequences_between_two_sequences.mojo",
    "nim": ROOT / "nim/n/number_of_increasing_sequences_between_two_sequences.nim",
    "odin": ROOT / "odin/n/number_of_increasing_sequences_between_two_sequences.odin",
    "rust": ROOT / "rust/n/number_of_increasing_sequences_between_two_sequences.rs",
    "v": ROOT / "v/n/number_of_increasing_sequences_between_two_sequences.v",
    "zig": ROOT / "zig/n/number_of_increasing_sequences_between_two_sequences.zig",
}
ORACLES = (PACKAGE / "primary_oracle.py", PACKAGE / "independent_oracle.py")
REQUIRED_CASES = {
    "official-sample-one",
    "official-sample-two-no-valid-sequence",
    "single-interval-three-values",
    "two-positions-full-small-domain",
    "three-position-nested-intervals",
    "maximum-n-and-m-forced-constant-sequence",
    "incompatible-position-intervals",
    "malformed-packed-length",
    "empty-position-count",
    "empty-interval",
    "upper-bound-exceeds-domain",
    "null-input",
}


def verify() -> list[str]:
    errors: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"workload cannot be read: {error}"]
    algorithm = "number_of_increasing_sequences_between_two_sequences"
    if workload.get("algorithm") != algorithm or workload.get("function_symbol") != algorithm:
        errors.append("algorithm or function symbol mismatch")
    if workload.get("oracle") != "benchmarks/n/number_of_increasing_sequences_between_two_sequences/primary_oracle.py":
        errors.append("primary oracle path mismatch")
    if workload.get("independent_oracle") != "benchmarks/n/number_of_increasing_sequences_between_two_sequences/independent_oracle.py":
        errors.append("independent oracle path mismatch")
    contract = workload.get("contract", {})
    if contract.get("modulus") != 998244353:
        errors.append("modulus mismatch")
    if contract.get("n_range") != [1, 64] or contract.get("m_range") != [1, 64]:
        errors.append("bounded n and m limits mismatch")
    if workload.get("input", {}).get("maximum_length") != 130:
        errors.append("packed input maximum length mismatch")
    if workload.get("input", {}).get("kind") != "signed_64_bit_integer_array":
        errors.append("input kind mismatch")
    if workload.get("output", {}).get("kind") != "signed_64_bit_scalar":
        errors.append("output kind mismatch")
    source = workload.get("source", {})
    if source.get("problem_url") != "https://judge.yosupo.jp/problem/number_of_increasing_sequences_between_two_sequences":
        errors.append("official Library Checker attribution missing")
    cases = workload.get("cases", [])
    case_ids = {case.get("id") for case in cases}
    if not REQUIRED_CASES <= case_ids:
        errors.append(f"missing required fixtures: {sorted(REQUIRED_CASES - case_ids)}")
    for case in cases:
        values = case.get("input_values", [])
        if case.get("input_length") != len(values):
            errors.append(f"fixture length mismatch: {case.get('id')}")
        if case.get("input_is_null") and values:
            errors.append(f"null fixture contains values: {case.get('id')}")
        if not case.get("input_is_null") and len(values) > 130:
            errors.append(f"fixture exceeds packed bound: {case.get('id')}")
    for language, path in PORTS.items():
        if not path.is_file():
            errors.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif algorithm not in path.read_text(encoding="utf-8"):
            errors.append(f"function symbol missing: {path.relative_to(ROOT)}")
    for path in ORACLES:
        if not path.is_file():
            errors.append(f"missing oracle: {path.name}")
    for name in ("README.md", "RIGHTS.md", "workload.json", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            errors.append(f"missing package file: {name}")
    return errors


if __name__ == "__main__":
    for error in verify():
        print(error)
