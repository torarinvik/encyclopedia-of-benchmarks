"""Static inventory for the bounded Fast Prime Sums package."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
from types import ModuleType

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/f/fast_prime_sums.c",
    "c3": "c3/f/fast_prime_sums.c3",
    "cpp": "cpp/f/fast_prime_sums.cpp",
    "elisa": "elisa/f/fast_prime_sums.elisa",
    "mojo": "mojo/f/fast_prime_sums.mojo",
    "nim": "nim/f/fast_prime_sums.nim",
    "odin": "odin/f/fast_prime_sums.odin",
    "rust": "rust/f/fast_prime_sums.rs",
    "v": "v/f/fast_prime_sums.v",
    "zig": "zig/f/fast_prime_sums.zig",
}
EXPECTED_CASES = {
    "zero", "one", "first-prime", "ten", "hundred", "one-thousand",
    "million", "published-one-hundred-million", "published-maximum",
    "negative", "first-unsupported", "signed-minimum", "signed-maximum",
}


def _load(name: str) -> ModuleType:
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
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
        primary = _load("primary_oracle")
        independent = _load("independent_oracle")
    except (OSError, json.JSONDecodeError, ImportError) as error:
        return [f"cannot load package metadata or references: {error}"]

    if (workload.get("algorithm") != "fast_prime_sums"
            or workload.get("function_symbol") != "fast_prime_sums"
            or workload.get("abi") != "i64_scalar"
            or workload.get("contract", {}).get("input_range") != [0, primary.MAX_INPUT]
            or workload.get("contract", {}).get("invalid_input_result") != -1):
        issues.append("workload identity, ABI, or input bounds differ from the package")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not all(isinstance(case, dict) for case in cases):
        return issues + ["workload cases must be a list of objects"]
    ids = {case.get("id") for case in cases}
    if len(ids) != len(cases) or ids != EXPECTED_CASES:
        issues.append("workload fixture IDs are duplicated or incomplete")
    for case in cases:
        case_id = case.get("id", "<unnamed>")
        value = case.get("input_value")
        expected = case.get("expected_result")
        if type(value) is not int or type(expected) is not int:
            issues.append(f"fixture values must be integers: {case_id}")
            continue
        if primary.expected_result(value) != expected:
            issues.append(f"primary fixture result mismatch: {case_id}")
        try:
            independent_result = independent.expected_result(value)
        except ValueError:
            issues.append(f"independent oracle lacks fixture coverage: {case_id}")
        else:
            if independent_result != expected:
                issues.append(f"independent fixture result mismatch: {case_id}")

    source_url = workload.get("source", {}).get("url")
    if (not isinstance(source_url, str) or source_url not in readme
            or source_url not in rights
            or "segmented sieve through `10^6`" not in readme
            or "Min_25" not in readme
            or "OEIS A046731" not in readme
            or "https://oeis.org/A046731" not in rights):
        issues.append("README/RIGHTS is missing provenance or distinctness details")

    for language, relative in PORTS.items():
        source = ROOT / relative
        if not source.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        if "fast_prime_sums" not in source.read_text(encoding="utf-8"):
            issues.append(f"exported symbol text missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README link missing for {language}")
    elisa = ROOT / PORTS["elisa"]
    if elisa.is_file():
        source = elisa.read_text(encoding="utf-8")
        if "mutable view[i64]" not in source or "UnsafePointer" in source or "*i64" in source:
            issues.append("Elisa should use an array view without raw pointers")
    return issues


def verify() -> None:
    issues = static_issues()
    if issues:
        raise ValueError("\n".join(issues))
