"""Static inventory checks for the bounded generalized CRT package."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/g/generalized_chinese_remainder_theorem"
SOURCES = {
    "c": ROOT / "c/g/generalized_chinese_remainder_theorem.c",
    "c3": ROOT / "c3/g/generalized_chinese_remainder_theorem.c3",
    "cpp": ROOT / "cpp/g/generalized_chinese_remainder_theorem.cpp",
    "elisa": ROOT / "elisa/g/generalized_chinese_remainder_theorem.elisa",
    "mojo": ROOT / "mojo/g/generalized_chinese_remainder_theorem.mojo",
    "nim": ROOT / "nim/g/generalized_chinese_remainder_theorem.nim",
    "odin": ROOT / "odin/g/generalized_chinese_remainder_theorem.odin",
    "rust": ROOT / "rust/g/generalized_chinese_remainder_theorem.rs",
    "v": ROOT / "v/g/generalized_chinese_remainder_theorem.v",
    "zig": ROOT / "zig/g/generalized_chinese_remainder_theorem.zig",
}
EXPECTED_CASES = {
    "single-congruence", "pairwise-coprime-system", "compatible-overlapping-moduli",
    "redundant-lower-prime-powers", "incompatible-parity", "same-prime-power-conflict",
    "consistent-repeated-modulus", "maximum-modulus-product", "trailing-word",
    "zero-equations", "too-many-equations", "modulus-one", "residue-not-canonical",
    "input-count-length-mismatch",
}


def static_issues() -> list[str]:
    """Check required files, exported symbols, and workload metadata without execution."""
    issues: list[str] = []
    required = (
        PACKAGE / "README.md", PACKAGE / "RIGHTS.md", PACKAGE / "workload.json",
        PACKAGE / "primary_oracle.py", PACKAGE / "independent_oracle.py",
    )
    for path in required:
        if not path.is_file():
            issues.append(f"missing {path.relative_to(ROOT)}")

    for language, path in SOURCES.items():
        if not path.is_file():
            issues.append(f"missing {path.relative_to(ROOT)}")
            continue
        source = path.read_text(encoding="utf-8")
        if "generalized_chinese_remainder_theorem" not in source:
            issues.append(f"{path.relative_to(ROOT)} lacks the exported ABI symbol")
        if language == "elisa" and "UnsafePointer" in source:
            issues.append("Elisa implementation should use its ABI reference instead of a raw pointer")

    workload_path = PACKAGE / "workload.json"
    if workload_path.is_file():
        try:
            workload = json.loads(workload_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            issues.append(f"invalid workload JSON: {error}")
        else:
            input_spec = workload.get("input", {})
            cases = workload.get("cases")
            case_ids = ({case.get("id") for case in cases}
                        if isinstance(cases, list) and all(isinstance(case, dict) for case in cases)
                        else set())
            if (workload.get("algorithm") != "generalized_chinese_remainder_theorem"
                    or workload.get("function_symbol") != "generalized_chinese_remainder_theorem"
                    or workload.get("abi") != "i64_array_scalar"
                    or input_spec.get("equation_count_range") != [1, 4]
                    or input_spec.get("modulus_range") != [2, 64]
                    or input_spec.get("maximum_valid_length") != 9
                    or input_spec.get("maximum_parseable_length") != 10
                    or workload.get("workspace", {}).get("bytes") != 2048):
                issues.append("workload metadata differs from the bounded scalar contract")
            if case_ids != EXPECTED_CASES:
                issues.append("workload case inventory differs from the reviewed fixtures")
    return issues


if __name__ == "__main__":
    for issue in static_issues():
        print(issue)
    if not static_issues():
        print("Generalized CRT package inventory is complete")
