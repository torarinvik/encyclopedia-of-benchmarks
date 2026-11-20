"""Static inventory and fixture review for Pocklington certificates."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
from types import ModuleType

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": ("c/p/pocklington_primality_certificate.c", "c/p/pocklington_primality_certificate.c"),
    "c3": ("c3/p/pocklington_primality_certificate.c3", "c3/p/pocklington_primality_certificate.c3"),
    "cpp": ("cpp/p/pocklington_primality_certificate.cpp", "cpp/p/pocklington_primality_certificate.cpp"),
    "elisa": ("elisa/p/pocklington_primality_certificate.elisa", "elisa/p/pocklington_primality_certificate.elisa"),
    "mojo": ("mojo/p/pocklington_primality_certificate.mojo", "mojo/p/pocklington_primality_certificate.mojo"),
    "nim": ("nim/p/pocklington_primality_certificate.nim", "nim/p/pocklington_primality_certificate.nim"),
    "odin": ("odin/p/pocklington_primality_certificate.odin", "odin/p/pocklington_primality_certificate.odin"),
    "rust": ("rust/p/pocklington_primality_certificate.rs", "rust/p/pocklington_primality_certificate.rs"),
    "v": ("v/p/pocklington_primality_certificate.v", "v/p/pocklington_primality_certificate.v"),
    "zig": ("zig/p/pocklington_primality_certificate.zig", "zig/p/pocklington_primality_certificate.zig"),
}
NULL_GUARDS = {
    "c": "values == NULL",
    "c3": "values == null",
    "cpp": "values == nullptr",
    "elisa": "input.is_null()",
    "mojo": "input == UnsafePointer[Int64, ImmutAnyOrigin]()",
    "nim": "input == nil",
    "odin": "values == nil",
    "rust": "input.is_null()",
    "v": "input == nil",
    "zig": "input == null",
}
EXPECTED_CASES = {
    "small-prime-certificate-seven", "small-prime-certificate-thirteen",
    "prime-certificate-with-three-factors", "composite-fermat-witness-fails",
    "composite-gcd-witness-fails", "well-formed-factored-part-too-small",
    "nonprime-factor-invalid", "nonminimal-factor-order-invalid",
    "factorization-mismatch-invalid", "maximum-n-domain-bound",
    "maximum-six-factor-frame-rejected-witness", "maximum-parseable-trailing-value",
    "null-input-zero-length", "null-input-maximum-parseable-length",
    "n-below-domain", "count-above-bound",
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

    if (workload.get("algorithm") != "pocklington_primality_certificate"
            or workload.get("function_symbol") != "pocklington_primality_certificate"
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("algorithm identity, symbol, or ABI mismatch")
    input_spec = workload.get("input", {})
    if (input_spec.get("n_range") != [3, primary.MAX_N]
            or input_spec.get("factor_count_range") != [1, primary.MAX_FACTORS]
            or input_spec.get("maximum_valid_length") != primary.MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != primary.MAX_PARSEABLE_INPUT_LENGTH):
        issues.append("workload input bounds differ from the primary oracle")
    if workload.get("output", {}).get("valid_result_range") != [0, 1]:
        issues.append("valid scalar result range mismatch")

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
        if "pocklington_primality_certificate" not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"null guard missing from {relative}")
        if f"](../../../{link_relative})" not in readme:
            issues.append(f"README link mismatch for {language}")
    elisa = (ROOT / PORTS["elisa"][0]).read_text(encoding="utf-8")
    if "view[i64]" not in elisa or "UnsafePointer" in elisa or "*i64" in elisa:
        issues.append("Elisa must use a view internally and avoid raw pointers")
    for url in (
        "https://upload.wikimedia.org/wikipedia/commons/e/eb/Proceedings_-_Cambridge_Philosophical_Society_%28IA_proceedingscambr18camb%29.pdf",
        "https://flintlib.org/doc/algorithms/number-theory/primality-proving.html",
    ):
        if url not in readme or url not in rights:
            issues.append(f"provenance URL missing from README or RIGHTS: {url}")
    return issues


def verify() -> None:
    """Raise when package inventory or fixture expectations are incomplete."""
    issues = static_issues()
    if issues:
        raise ValueError("\n".join(issues))
