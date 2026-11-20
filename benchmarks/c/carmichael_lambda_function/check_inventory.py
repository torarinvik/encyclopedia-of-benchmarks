"""Static source inventory and fixture review for Carmichael's lambda function."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
from types import ModuleType

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": ("c/c/carmichael_lambda_function.c", "c/c/carmichael_lambda_function.c"),
    "c3": ("c3/c/carmichael_lambda_function.c3", "c3/c/carmichael_lambda_function.c3"),
    "cpp": ("cpp/c/carmichael_lambda_function.cpp", "cpp/c/carmichael_lambda_function.cpp"),
    "elisa": ("elisa/c/carmichael_lambda_function.elisa", "elisa/c/carmichael_lambda_function.elisa"),
    "mojo": ("mojo/c/carmichael_lambda_function.mojo", "mojo/c/carmichael_lambda_function.mojo"),
    "nim": ("nim/c/carmichael_lambda_function.nim", "nim/c/carmichael_lambda_function.nim"),
    "odin": ("odin/c/carmichael_lambda_function.odin", "odin/c/carmichael_lambda_function.odin"),
    "rust": ("rust/c/carmichael_lambda_function.rs", "rust/c/carmichael_lambda_function.rs"),
    "v": ("v/c/carmichael_lambda_function.v", "v/c/carmichael_lambda_function.v"),
    "zig": ("zig/c/carmichael_lambda_function.zig", "zig/c/carmichael_lambda_function.zig"),
}
EXPECTED_CASES = {
    "unit-modulus-one", "prime-two", "two-squared", "two-cubed", "two-to-fourth",
    "two-to-fifth", "odd-prime-square", "odd-prime-power", "mixed-prime-powers",
    "coprime-prime-power-lcm", "mixed-two-and-odd-powers", "mixed-prime-power-lcm",
    "carmichael-number-still-returns-exponent", "prime-maximum-near-bound",
    "maximum-power-of-two", "zero-invalid", "negative-invalid", "above-bound-invalid",
    "trailing-word", "null-input",
}
NULL_GUARDS = {
    "c": "input == NULL",
    "c3": "input == null",
    "cpp": "input == nullptr",
    "elisa": "input.is_null()",
    "mojo": "input == UnsafePointer[Int64, ImmutAnyOrigin]()",
    "nim": "input == nil",
    "odin": "input == nil",
    "rust": "input.is_null()",
    "v": "input == nil",
    "zig": "input == null",
}


def _load_oracle(name: str) -> ModuleType:
    spec = importlib.util.spec_from_file_location(name, PACKAGE / f"{name}.py")
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load {name}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    primary = _load_oracle("primary_oracle")
    independent = _load_oracle("independent_oracle")
    if (workload.get("algorithm") != "carmichael_lambda_function"
            or workload.get("function_symbol") != "carmichael_lambda_function"
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("algorithm identity, exported symbol, or ABI mismatch")
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (input_spec.get("n_range") != [1, primary.MAX_N]
            or input_spec.get("exact_length") != 1
            or input_spec.get("maximum_valid_length") != primary.MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != primary.MAX_PARSEABLE_INPUT_LENGTH):
        issues.append("input bounds differ from the primary oracle")
    if (output_spec.get("valid_result_range") != [primary.MIN_RESULT, primary.MAX_RESULT]
            or output_spec.get("invalid_input_result") != primary.INVALID_RESULT):
        issues.append("output bounds differ from the primary oracle")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not all(isinstance(case, dict) for case in cases):
        return issues + ["workload cases must be a list of objects"]
    case_ids = {case.get("id") for case in cases}
    if len(case_ids) != len(cases) or case_ids != EXPECTED_CASES:
        issues.append("fixture IDs are duplicated or differ from the reviewed inventory")
    for case in cases:
        case_id = case.get("id", "<unnamed>")
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"input frame length mismatch: {case_id}")
            continue
        arguments = {
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = case.get("expected_result")
        if primary.expected_result(values, **arguments) != expected:
            issues.append(f"primary fixture result mismatch: {case_id}")
        if independent.expected_result(values, **arguments) != expected:
            issues.append(f"independent fixture result mismatch: {case_id}")

    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    except OSError as error:
        return issues + [f"cannot read package documentation: {error}"]
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "check_inventory.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, (relative, link_relative) in PORTS.items():
        source_path = ROOT / relative
        if not source_path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        source = source_path.read_text(encoding="utf-8")
        if "carmichael_lambda_function" not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"null guard missing from {relative}")
        if f"](../../../{link_relative})" not in readme:
            issues.append(f"README source link mismatch for {language}")
    elisa_source = (ROOT / PORTS["elisa"][0]).read_text(encoding="utf-8")
    if "UnsafePointer" in elisa_source or "*i64" in elisa_source:
        issues.append("Elisa port should keep pointer use out of the implementation")
    for source_url in (
        "https://webspace.maths.qmul.ac.uk/r.a.wilson/MAS335/cn7.pdf",
        "https://mathworld.wolfram.com/CarmichaelFunction.html",
    ):
        if source_url not in readme or source_url not in rights:
            issues.append(f"provenance URL missing from README or RIGHTS: {source_url}")
    return issues


def verify() -> None:
    """Raise if static package inventory or fixture expectations are incomplete."""
    issues = static_issues()
    if issues:
        raise ValueError("\n".join(issues))
