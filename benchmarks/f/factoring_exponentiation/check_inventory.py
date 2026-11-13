"""Static source and workload inventory for binary exponentiation by factoring."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/f/factoring_exponentiation"
SOURCES = {
    "c": ROOT / "c/f/factoring_exponentiation.c",
    "c3": ROOT / "c3/f/factoring_exponentiation.c3",
    "cpp": ROOT / "cpp/f/factoring_exponentiation.cpp",
    "elisa": ROOT / "elisa/f/factoring_exponentiation.elisa",
    "mojo": ROOT / "mojo/f/factoring_exponentiation.mojo",
    "nim": ROOT / "nim/f/factoring_exponentiation.nim",
    "odin": ROOT / "odin/f/factoring_exponentiation.odin",
    "rust": ROOT / "rust/f/factoring_exponentiation.rs",
    "v": ROOT / "v/f/factoring_exponentiation.v",
    "zig": ROOT / "zig/f/factoring_exponentiation.zig",
}
NULL_GUARDS = {
    "c": "input == NULL",
    "c3": "input == null",
    "cpp": "input == nullptr",
    "elisa": "input == null",
    "mojo": "input == UnsafePointer[Int64, ImmutAnyOrigin]()",
    "nim": "input == nil",
    "odin": "input == nil",
    "rust": "input.is_null()",
    "v": "input == nil",
    "zig": "input == null",
}
EXPECTED_CASES = {
    "zero-exponent-small-modulus", "base-three-mod-sixteen", "factored-exponent-small",
    "negative-unit-normalization", "thirty-two-bit-modulus", "maximum-remainder",
    "maximum-exponent-identity-base", "zero-remainder", "even-base-invalid",
    "remainder-outside-modulus", "modulus-exponent-too-small",
    "modulus-exponent-too-large", "zero-base-invalid", "negative-exponent-invalid",
    "trailing-word-invalid",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    for relative in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / relative).is_file():
            issues.append(f"missing {PACKAGE.relative_to(ROOT) / relative}")
    for language, path in SOURCES.items():
        if not path.is_file():
            issues.append(f"missing {path.relative_to(ROOT)}")
            continue
        source = path.read_text(encoding="utf-8")
        if "factoring_exponentiation" not in source:
            issues.append(f"{path.relative_to(ROOT)} lacks the exported ABI symbol")
        if NULL_GUARDS[language] not in source:
            issues.append(f"{path.relative_to(ROOT)} lacks the documented null-input guard")
        if language == "elisa" and ("UnsafePointer" in source or "*i64" in source):
            issues.append("Elisa must use fixed internal values and an ABI reference")

    workload_path = PACKAGE / "workload.json"
    if workload_path.is_file():
        try:
            workload = json.loads(workload_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            issues.append(f"invalid workload JSON: {error}")
        else:
            cases = workload.get("cases")
            case_ids = (
                {case.get("id") for case in cases}
                if isinstance(cases, list) and all(isinstance(case, dict) for case in cases)
                else set()
            )
            if (
                workload.get("algorithm") != "factoring_exponentiation"
                or workload.get("function_symbol") != "factoring_exponentiation"
                or workload.get("abi") != "i64_array_scalar"
                or workload.get("input", {}).get("maximum_valid_input_length") != 4
                or workload.get("input", {}).get("maximum_parseable_input_length") != 5
                or workload.get("workspace", {}).get("bytes") != 512
            ):
                issues.append("workload metadata differs from the bounded scalar contract")
            if case_ids != EXPECTED_CASES:
                issues.append("workload case inventory differs from the reviewed fixtures")
    return issues
