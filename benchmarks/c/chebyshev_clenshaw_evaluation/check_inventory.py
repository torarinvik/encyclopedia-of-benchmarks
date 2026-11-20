"""Static workload, oracle, and ten-port inventory for Clenshaw evaluation."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .primary_oracle import (
        INVALID_RESULT,
        MAX_DEGREE,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        MAX_RESULT,
        MODULUS,
        expected_result as primary_result,
    )
    from .independent_oracle import (
        expected_result as independent_result,
        verify_candidate,
    )
except ImportError:  # Direct import from this package directory.
    from primary_oracle import (
        INVALID_RESULT,
        MAX_DEGREE,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        MAX_RESULT,
        MODULUS,
        expected_result as primary_result,
    )
    from independent_oracle import (
        expected_result as independent_result,
        verify_candidate,
    )

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "chebyshev_clenshaw_evaluation"
PORTS = {
    "c": (ROOT / "c/c/chebyshev_clenshaw_evaluation.c", "c/c/chebyshev_clenshaw_evaluation.c"),
    "c3": (ROOT / "c3/c/chebyshev_clenshaw_evaluation.c3", "c3/c/chebyshev_clenshaw_evaluation.c3"),
    "cpp": (ROOT / "cpp/c/chebyshev_clenshaw_evaluation.cpp", "cpp/c/chebyshev_clenshaw_evaluation.cpp"),
    "elisa": (ROOT / "elisa/c/chebyshev_clenshaw_evaluation.elisa", "elisa/c/chebyshev_clenshaw_evaluation.elisa"),
    "mojo": (ROOT / "mojo/c/chebyshev_clenshaw_evaluation.mojo", "mojo/c/chebyshev_clenshaw_evaluation.mojo"),
    "nim": (ROOT / "nim/c/chebyshev_clenshaw_evaluation.nim", "nim/c/chebyshev_clenshaw_evaluation.nim"),
    "odin": (ROOT / "odin/c/chebyshev_clenshaw_evaluation.odin", "odin/c/chebyshev_clenshaw_evaluation.odin"),
    "rust": (ROOT / "rust/c/chebyshev_clenshaw_evaluation.rs", "rust/c/chebyshev_clenshaw_evaluation.rs"),
    "v": (ROOT / "v/c/chebyshev_clenshaw_evaluation.v", "v/c/chebyshev_clenshaw_evaluation.v"),
    "zig": (ROOT / "zig/c/chebyshev_clenshaw_evaluation.zig", "zig/c/chebyshev_clenshaw_evaluation.zig"),
}
REQUIRED_CASES = {
    "degree-zero", "linear-nonzero-point", "only-second-chebyshev-term",
    "cubic-at-positive-endpoint", "cubic-at-negative-endpoint", "even-terms-at-zero",
    "third-basis-polynomial-at-two", "field-wraparound", "maximum-degree-at-one",
    "maximum-degree-at-negative-one", "maximum-degree-at-zero",
    "zero-polynomial-at-maximum-degree", "negative-degree", "degree-too-large",
    "negative-field-point", "field-point-not-canonical", "coefficient-not-canonical",
    "short-frame", "trailing-word",
    "null-input", "parseable-bound-trailing-frame",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("workload identity or ABI mismatch")
    source = workload.get("source", {})
    if source.get("url") != "https://dlmf.nist.gov/3.11":
        issues.append("primary source URL mismatch")
    input_spec = workload.get("input", {})
    if (input_spec.get("degree_range") != [0, MAX_DEGREE]
            or input_spec.get("field_modulus") != MODULUS
            or input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH):
        issues.append("input bounds mismatch")
    if workload.get("output", {}).get("valid_result_range") != [0, MAX_RESULT]:
        issues.append("result bounds mismatch")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases must be a nonempty list"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid workload case")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture id: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        input_is_null = case.get("input_is_null", False)
        input_length = case.get("input_length")
        if (not isinstance(values, list) or type(input_is_null) is not bool
                or type(input_length) is not int
                or not input_is_null and input_length != len(values)
                or input_is_null and values):
            issues.append(f"input framing mismatch: {case_id}")
            continue
        expected = case.get("expected_result")
        primary = primary_result(values, input_is_null, input_length)
        independent = independent_result(values, input_is_null, input_length)
        if type(expected) is not int or expected != primary:
            issues.append(f"primary fixture mismatch: {case_id}")
        if primary != independent or not verify_candidate(
                values, expected, input_is_null, input_length):
            issues.append(f"independent fixture mismatch: {case_id}")
    if not REQUIRED_CASES <= seen:
        issues.append("missing fixtures: " + ", ".join(sorted(REQUIRED_CASES - seen)))

    readme_path = PACKAGE / "README.md"
    readme = readme_path.read_text(encoding="utf-8")
    for language, (path, relative) in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} source: {path.relative_to(ROOT)}")
            continue
        source_text = path.read_text(encoding="utf-8")
        if SYMBOL not in source_text:
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README source link mismatch for {language}")
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    return issues


def verify() -> None:
    """Raise when package inventory or fixture expectations are incomplete."""
    issues = static_issues()
    if issues:
        raise ValueError("\n".join(issues))


if __name__ == "__main__":
    verify()
