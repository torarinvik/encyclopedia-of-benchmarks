"""Static workload, reference, and ten-language inventory for convergents."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from . import independent_oracle, primary_oracle
except ImportError:  # Direct import from this package directory.
    import independent_oracle
    import primary_oracle

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "continued_fraction_convergents"
SOURCE_URL = "https://cp-algorithms.com/algebra/continued-fractions.html#convergents"
PORTS = {
    "c": ("c/c/continued_fraction_convergents.c", "c/c/continued_fraction_convergents.c"),
    "c3": ("c3/c/continued_fraction_convergents.c3", "c3/c/continued_fraction_convergents.c3"),
    "cpp": ("cpp/c/continued_fraction_convergents.cpp", "cpp/c/continued_fraction_convergents.cpp"),
    "elisa": ("elisa/c/continued_fraction_convergents.elisa", "elisa/c/continued_fraction_convergents.elisa"),
    "mojo": ("mojo/c/continued_fraction_convergents.mojo", "mojo/c/continued_fraction_convergents.mojo"),
    "nim": ("nim/c/continued_fraction_convergents.nim", "nim/c/continued_fraction_convergents.nim"),
    "odin": ("odin/c/continued_fraction_convergents.odin", "odin/c/continued_fraction_convergents.odin"),
    "rust": ("rust/c/continued_fraction_convergents.rs", "rust/c/continued_fraction_convergents.rs"),
    "v": ("v/c/continued_fraction_convergents.v", "v/c/continued_fraction_convergents.v"),
    "zig": ("zig/c/continued_fraction_convergents.zig", "zig/c/continued_fraction_convergents.zig"),
}
EXPECTED_CASES = {
    "three-coefficient-example", "mixed-tail-coefficients", "negative-integer-part",
    "zero-and-one-prefixes", "maximum-coefficient-count", "trailing-word",
    "zero-coefficient-count", "count-above-bound", "first-coefficient-out-of-range",
    "zero-tail-coefficient", "tail-coefficient-above-bound", "input-count-length-mismatch",
    "short-output-buffer", "null-output", "invalid-before-output-check", "null-input",
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
            or workload.get("abi") != "i64_array_bytes_output"):
        issues.append("workload identity or ABI mismatch")
    if workload.get("source", {}).get("url") != SOURCE_URL:
        issues.append("workload source URL mismatch")
    input_spec = workload.get("input", {})
    if (input_spec.get("coefficient_count_range") != [1, primary_oracle.MAX_COEFFICIENTS]
            or input_spec.get("maximum_valid_length") != primary_oracle.MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != primary_oracle.MAX_PARSEABLE_INPUT_LENGTH):
        issues.append("input limits differ from the primary reference")
    output_spec = workload.get("output", {})
    if output_spec.get("maximum_bytes") != primary_oracle.MAX_OUTPUT_BYTES:
        issues.append("maximum output size differs from the primary reference")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not all(isinstance(case, dict) for case in cases):
        return issues + ["workload cases must be a list of objects"]
    case_ids = [case.get("id") for case in cases]
    if len(set(case_ids)) != len(case_ids) or set(case_ids) != EXPECTED_CASES:
        issues.append("fixture IDs are duplicated or differ from the reviewed inventory")
    for case in cases:
        case_id = case.get("id", "<unnamed>")
        values = case.get("input_values")
        if (not isinstance(values, list) or type(case.get("input_length")) is not int
                or case["input_length"] != len(values)):
            issues.append(f"input frame length mismatch: {case_id}")
            continue
        arguments = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = (case.get("expected_result"), case.get("expected_output_hex"))
        primary = primary_oracle.expected_output(values, **arguments)
        independent = independent_oracle.expected_output(values, **arguments)
        expected_bytes = bytes.fromhex(expected[1]) if isinstance(expected[1], str) else None
        if expected[0] != primary[0] or expected_bytes != primary[1]:
            issues.append(f"primary fixture mismatch: {case_id}")
        if primary != independent:
            issues.append(f"independent reference disagreement: {case_id}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "check_inventory.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    if SOURCE_URL not in readme or SOURCE_URL not in rights:
        issues.append("source URL missing from package documentation")
    for language, (relative, readme_relative) in PORTS.items():
        source_path = ROOT / relative
        if not source_path.is_file():
            issues.append(f"missing {language} source: {relative}")
            continue
        source = source_path.read_text(encoding="utf-8")
        if SYMBOL not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if f"](../../../{readme_relative})" not in readme:
            issues.append(f"README source link mismatch for {language}")
    elisa_path = ROOT / PORTS["elisa"][0]
    if elisa_path.is_file():
        elisa_source = elisa_path.read_text(encoding="utf-8")
        if "UnsafePointer" in elisa_source or "*i64" in elisa_source:
            issues.append("Elisa implementation should not introduce raw pointers")
    return issues


def verify() -> None:
    """Raise if static fixture metadata or package inventory is incomplete."""
    issues = static_issues()
    if issues:
        raise ValueError("\n".join(issues))


if __name__ == "__main__":
    verify()
