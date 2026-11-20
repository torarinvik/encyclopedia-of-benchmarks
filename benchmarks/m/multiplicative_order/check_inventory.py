"""Static workload, dual-reference, and ten-port inventory."""

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
SYMBOL = "multiplicative_order"
SOURCE_URL = "https://cp-algorithms.com/algebra/primitive-root.html"
PORTS = {
    "c": ("c/m/multiplicative_order.c", "c/m/multiplicative_order.c"),
    "c3": ("c3/m/multiplicative_order.c3", "c3/m/multiplicative_order.c3"),
    "cpp": ("cpp/m/multiplicative_order.cpp", "cpp/m/multiplicative_order.cpp"),
    "elisa": ("elisa/m/multiplicative_order.elisa", "elisa/m/multiplicative_order.elisa"),
    "mojo": ("mojo/m/multiplicative_order.mojo", "mojo/m/multiplicative_order.mojo"),
    "nim": ("nim/m/multiplicative_order.nim", "nim/m/multiplicative_order.nim"),
    "odin": ("odin/m/multiplicative_order.odin", "odin/m/multiplicative_order.odin"),
    "rust": ("rust/m/multiplicative_order.rs", "rust/m/multiplicative_order.rs"),
    "v": ("v/m/multiplicative_order.v", "v/m/multiplicative_order.v"),
    "zig": ("zig/m/multiplicative_order.zig", "zig/m/multiplicative_order.zig"),
}
EXPECTED_CASES = {
    "identity-mod-two", "identity-at-maximum-modulus", "order-three-prime-modulus",
    "full-order-prime-residue", "proper-order-prime-residue", "composite-prime-power-modulus",
    "composite-modulus-order-two", "power-of-two-modulus", "composite-modulus-order-four",
    "composite-modulus-order-four-two", "negative-one-residue", "nonunit-even-residue",
    "zero-residue", "shared-factor-nonunit", "modulus-below-profile", "modulus-above-profile",
    "negative-base", "base-equals-modulus", "short-frame", "trailing-word",
    "input-length-mismatch", "null-input",
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
    if workload.get("source", {}).get("url") != SOURCE_URL:
        issues.append("source URL mismatch")
    input_spec = workload.get("input", {})
    if (input_spec.get("modulus_range") != [primary_oracle.MIN_MODULUS, primary_oracle.MAX_MODULUS]
            or input_spec.get("exact_length") != 2
            or input_spec.get("maximum_valid_length") != primary_oracle.MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != primary_oracle.MAX_PARSEABLE_INPUT_LENGTH):
        issues.append("input bounds differ from the primary reference")
    output_spec = workload.get("output", {})
    if (output_spec.get("nonunit_result") != primary_oracle.NONUNIT_RESULT
            or output_spec.get("invalid_input_result") != primary_oracle.INVALID_RESULT):
        issues.append("output conventions differ from the primary reference")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not all(isinstance(case, dict) for case in cases):
        return issues + ["workload cases must be a list of objects"]
    case_ids = [case.get("id") for case in cases]
    if len(set(case_ids)) != len(case_ids) or set(case_ids) != EXPECTED_CASES:
        issues.append("fixture IDs are duplicated or differ from the reviewed inventory")
    for case in cases:
        case_id = case.get("id", "<unnamed>")
        values = case.get("input_values")
        input_length = case.get("input_length")
        input_is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(input_length) is not int
                or type(input_is_null) is not bool
                or (input_is_null and (values or input_length != 0))):
            issues.append(f"input frame mismatch: {case_id}")
            continue
        arguments = {"input_is_null": input_is_null, "input_length": input_length}
        expected = case.get("expected_result")
        primary = primary_oracle.expected_result(values, **arguments)
        independent = independent_oracle.expected_result(values, **arguments)
        if type(expected) is not int or expected != primary:
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
            issues.append("Elisa implementation should use views at the ABI boundary")
    return issues


def verify() -> None:
    """Raise if static package inventory or fixture expectations are incomplete."""
    issues = static_issues()
    if issues:
        raise ValueError("\n".join(issues))


if __name__ == "__main__":
    verify()
