"""Static package inventory checks for the bounded Fermat factor profile."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/f/fermat_factorization"
SOURCES = {
    "c": ROOT / "c/f/fermat_factorization.c",
    "c3": ROOT / "c3/f/fermat_factorization.c3",
    "cpp": ROOT / "cpp/f/fermat_factorization.cpp",
    "elisa": ROOT / "elisa/f/fermat_factorization.elisa",
    "mojo": ROOT / "mojo/f/fermat_factorization.mojo",
    "nim": ROOT / "nim/f/fermat_factorization.nim",
    "odin": ROOT / "odin/f/fermat_factorization.odin",
    "rust": ROOT / "rust/f/fermat_factorization.rs",
    "v": ROOT / "v/f/fermat_factorization.v",
    "zig": ROOT / "zig/f/fermat_factorization.zig",
}
EXPECTED_CASES = {
    "nearby-factors-after-two-misses", "first-candidate-factor-pair",
    "perfect-square-input", "close-semiprime-at-initial-candidate",
    "prime-no-hit-within-bound", "maximum-step-budget", "zero-candidate-budget", "trailing-word",
    "number-below-range", "even-number", "number-above-range",
    "negative-step-budget", "step-budget-above-range",
}


def static_issues() -> list[str]:
    """Check package files, source symbols, and workload metadata without execution."""
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
        if "fermat_factorization" not in source:
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
            if (workload.get("algorithm") != "fermat_factorization"
                    or workload.get("function_symbol") != "fermat_factorization"
                    or workload.get("abi") != "i64_array_scalar"
                    or input_spec.get("maximum_valid_length") != 2
                    or input_spec.get("maximum_parseable_length") != 3
                    or input_spec.get("max_steps_range") != [0, 4096]
                    or workload.get("workspace", {}).get("bytes") != 256):
                issues.append("workload metadata differs from the bounded i64_array_scalar contract")
            if case_ids != EXPECTED_CASES:
                issues.append("workload case inventory differs from the reviewed fixtures")
    return issues


if __name__ == "__main__":
    for issue in static_issues():
        print(issue)
    if not static_issues():
        print("Fermat factorization package inventory is complete")
