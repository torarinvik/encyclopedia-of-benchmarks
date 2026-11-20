"""Static port inventory and workload/reference review for Pohlig–Hellman."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
from types import ModuleType

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": ("c/p/pohlig_hellman_discrete_log.c", "c/p/pohlig_hellman_discrete_log.c"),
    "c3": ("c3/p/pohlig_hellman_discrete_log.c3", "c3/p/pohlig_hellman_discrete_log.c3"),
    "cpp": ("cpp/p/pohlig_hellman_discrete_log.cpp", "cpp/p/pohlig_hellman_discrete_log.cpp"),
    "elisa": ("elisa/p/pohlig_hellman_discrete_log.elisa", "elisa/p/pohlig_hellman_discrete_log.elisa"),
    "mojo": ("mojo/p/pohlig_hellman_discrete_log.mojo", "mojo/p/pohlig_hellman_discrete_log.mojo"),
    "nim": ("nim/p/pohlig_hellman_discrete_log.nim", "nim/p/pohlig_hellman_discrete_log.nim"),
    "odin": ("odin/p/pohlig_hellman_discrete_log.odin", "odin/p/pohlig_hellman_discrete_log.odin"),
    "rust": ("rust/p/pohlig_hellman_discrete_log.rs", "rust/p/pohlig_hellman_discrete_log.rs"),
    "v": ("v/p/pohlig_hellman_discrete_log.v", "v/p/pohlig_hellman_discrete_log.v"),
    "zig": ("zig/p/pohlig_hellman_discrete_log.zig", "zig/p/pohlig_hellman_discrete_log.zig"),
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
EXPECTED_CASES = {
    "smooth-order-p97", "less-smooth-order-p101", "proper-subgroup-member",
    "primitive-base-log", "order-one-base", "order-one-nonmember",
    "nonmember-target", "zero-target-nonmember", "maximum-prime-modulus",
    "composite-modulus-invalid", "modulus-below-bound", "zero-base-invalid",
    "target-at-modulus-invalid", "trailing-word", "null-input-zero-length",
    "null-input-maximum-parseable-length",
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
    if (workload.get("algorithm") != "pohlig_hellman_discrete_log"
            or workload.get("function_symbol") != "pohlig_hellman_discrete_log"
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("algorithm identity, symbol, or ABI mismatch")
    input_spec = workload.get("input", {})
    if (input_spec.get("p_range") != [primary.MIN_P, primary.MAX_P]
            or input_spec.get("exact_length") != 3
            or input_spec.get("maximum_valid_length") != primary.MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != primary.MAX_PARSEABLE_INPUT_LENGTH):
        issues.append("workload input bounds differ from primary oracle")
    if workload.get("output", {}).get("valid_result_range") != [-2, primary.MAX_P - 2]:
        issues.append("valid output range mismatch")

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
        if "pohlig_hellman_discrete_log" not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"null guard missing from {relative}")
        if f"](../../../{link_relative})" not in readme:
            issues.append(f"README source link mismatch for {language}")
    elisa = (ROOT / PORTS["elisa"][0]).read_text(encoding="utf-8")
    if "input: view[i64]" not in elisa or "UnsafePointer" in elisa or "*i64" in elisa:
        issues.append("Elisa port should use a view internally and avoid raw pointers")
    for url in (
        "https://ee.stanford.edu/~hellman/publications/28.pdf",
        "https://flintlib.org/doc/algorithms/number-theory/discrete-log.html",
    ):
        if url not in readme or url not in rights:
            issues.append(f"provenance URL missing from README or RIGHTS: {url}")
    return issues


def verify() -> None:
    """Raise when package inventory or fixture expectations are incomplete."""
    issues = static_issues()
    if issues:
        raise ValueError("\n".join(issues))
