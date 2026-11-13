"""Static inventory and workload checks for the Pollard p−1 package."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
from types import ModuleType

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/p/pollard_p_minus_one_factorization"
SOURCES = {
    "c": ROOT / "c/p/pollard_p_minus_one_factorization.c",
    "c3": ROOT / "c3/p/pollard_p_minus_one_factorization.c3",
    "cpp": ROOT / "cpp/p/pollard_p_minus_one_factorization.cpp",
    "elisa": ROOT / "elisa/p/pollard_p_minus_one_factorization.elisa",
    "mojo": ROOT / "mojo/p/pollard_p_minus_one_factorization.mojo",
    "nim": ROOT / "nim/p/pollard_p_minus_one_factorization.nim",
    "odin": ROOT / "odin/p/pollard_p_minus_one_factorization.odin",
    "rust": ROOT / "rust/p/pollard_p_minus_one_factorization.rs",
    "v": ROOT / "v/p/pollard_p_minus_one_factorization.v",
    "zig": ROOT / "zig/p/pollard_p_minus_one_factorization.zig",
}
EXPECTED_CASES = {
    "smooth-predecessor-factor", "larger-bound-finds-factor", "base-already-shares-factor",
    "prime-stage-reaches-whole-modulus", "smoothness-bound-too-small",
    "small-bound-finds-small-factor", "maximum-number-and-bound", "trailing-word",
    "number-too-small", "bound-too-large", "base-outside-modulus",
}


def _load_oracle(name: str) -> ModuleType | None:
    path = PACKAGE / f"{name}_oracle.py"
    spec = importlib.util.spec_from_file_location(f"pollard_p_minus_one_{name}", path)
    if spec is None or spec.loader is None:
        return None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def static_issues() -> list[str]:
    issues: list[str] = []
    required = (PACKAGE / "README.md", PACKAGE / "RIGHTS.md", PACKAGE / "workload.json",
                PACKAGE / "primary_oracle.py", PACKAGE / "independent_oracle.py")
    for path in required:
        if not path.is_file():
            issues.append(f"missing {path.relative_to(ROOT)}")
    for language, path in SOURCES.items():
        if not path.is_file():
            issues.append(f"missing {path.relative_to(ROOT)}")
            continue
        source = path.read_text(encoding="utf-8")
        if "pollard_p_minus_one_factorization" not in source:
            issues.append(f"{path.relative_to(ROOT)} lacks the exported ABI symbol")
        if language == "elisa" and ("UnsafePointer" in source or "*i64" in source):
            issues.append("Elisa implementation must use safe arithmetic and ABI references only")

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
            if (workload.get("algorithm") != "pollard_p_minus_one_factorization"
                    or workload.get("function_symbol") != "pollard_p_minus_one_factorization"
                    or workload.get("abi") != "i64_array_scalar"
                    or input_spec.get("maximum_valid_length") != 3
                    or input_spec.get("maximum_parseable_length") != 4
                    or workload.get("workspace", {}).get("bytes") != 1024):
                issues.append("workload metadata differs from the bounded i64_array_scalar contract")
            if case_ids != EXPECTED_CASES:
                issues.append("workload case inventory differs from the reviewed fixtures")
    return issues


def verify_workload() -> list[str]:
    """Compare declared scalar fixtures with both Python oracles."""
    issues = static_issues()
    if issues:
        return issues
    primary = _load_oracle("primary")
    independent = _load_oracle("independent")
    if primary is None or independent is None:
        return ["could not load package oracle modules"]
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    for case in workload["cases"]:
        values = case.get("input_values", [])
        expected = case.get("expected_result")
        for label, oracle in (("primary", primary), ("independent", independent)):
            actual = oracle.expected_result(values)
            if actual != expected:
                issues.append(f"{label} oracle disagrees with workload case {case.get('id')}")
    return issues
