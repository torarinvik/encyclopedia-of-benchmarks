"""Static workload, oracle, provenance, and ten-port inventory checks."""

from __future__ import annotations

import json
from pathlib import Path
import re

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "adaptive_heap_sort"
SOURCE_PATHS = (
    "c/a/adaptive_heap_sort.c",
    "c3/a/adaptive_heap_sort.c3",
    "cpp/a/adaptive_heap_sort.cpp",
    "elisa/a/adaptive_heap_sort.elisa",
    "mojo/a/adaptive_heap_sort.mojo",
    "nim/a/adaptive_heap_sort.nim",
    "odin/a/adaptive_heap_sort.odin",
    "rust/a/adaptive_heap_sort.rs",
    "v/a/adaptive_heap_sort.v",
    "zig/a/adaptive_heap_sort.zig",
)

try:
    from .independent_oracle import expected_result as independent_result
    from .primary_oracle import MAX_LENGTH, expected_result as primary_result
except ImportError:  # Direct invocation from the package directory.
    from independent_oracle import expected_result as independent_result  # type: ignore[no-redef]
    from primary_oracle import MAX_LENGTH, expected_result as primary_result  # type: ignore[no-redef]


def verify_workload(workload: object | None = None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                 "primary_oracle.py", "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    if not (ROOT / "benchmarks/verify_adaptive_heap_sort.py").is_file():
        issues.append("missing custom sort_call verifier")
    for source in SOURCE_PATHS:
        path = ROOT / source
        if not path.is_file():
            issues.append(f"missing port: {source}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {source}")

    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload must be an object"]
    profile = workload.get("profile", {})
    input_spec = workload.get("input", {})
    measurement = workload.get("measurement", {})
    source = workload.get("source", {})
    if not isinstance(profile, dict):
        profile = {}
    if not isinstance(input_spec, dict):
        input_spec = {}
    generation = input_spec.get("generation", {})
    if not isinstance(generation, dict):
        generation = {}
    if not isinstance(measurement, dict):
        measurement = {}
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or input_spec.get("kind") != "signed_i64_array"
            or input_spec.get("lengths") != [0, 1, 16, 64, 256, MAX_LENGTH]
            or generation.get("kind") != "modular_affine"
            or generation.get("multiplier") != 48271
            or generation.get("modulus") != 2000003
            or generation.get("offset") != 1000001
            or profile.get("maximum_length") != MAX_LENGTH
            or profile.get("minimum_value") != -(1 << 63)
            or profile.get("maximum_value") != (1 << 63) - 1
            or profile.get("stable") is not True
            or profile.get("workspace_bytes") != 40960
            or profile.get("randomized_tree") is not False
            or measurement.get("comparison_model") != "sort_call"
            or not isinstance(source, dict)
            or source.get("url") != "https://xlinux.nist.gov/dads/HTML/adaptiveHeapSort.html"
            or "RBST" not in source.get("description_mismatch", "")
            or "Cartesian tree" not in source.get("description_mismatch", "")):
        issues.append("workload identity, input, source distinction, or profile differs")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing semantic workload cases"]
    seen: set[str] = set()
    for case in cases:
        if (not isinstance(case, dict) or not isinstance(case.get("id"), str)
                or not isinstance(case.get("input_values"), list)
                or not isinstance(case.get("expected_values"), list)):
            issues.append("invalid Adaptive Heapsort workload case")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate workload case: {case_id}")
        seen.add(case_id)
        values = case["input_values"]
        expected = case["expected_values"]
        try:
            primary_expected = primary_result(values)
            independent_expected = independent_result(values)
        except (TypeError, ValueError):
            issues.append(f"invalid oracle input: {case_id}")
            continue
        if primary_expected != expected or independent_expected != expected:
            issues.append(f"oracle fixture mismatch: {case_id}")

    readme_path = PACKAGE / "README.md"
    rights_path = PACKAGE / "RIGHTS.md"
    if readme_path.is_file() and rights_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        rights = rights_path.read_text(encoding="utf-8")
        source_url = source.get("url") if isinstance(source, dict) else None
        primary_url = source.get("primary_method_source") if isinstance(source, dict) else None
        for url in (source_url, primary_url, "https://arxiv.org/abs/2404.04552"):
            if not isinstance(url, str) or url not in readme or url not in rights:
                issues.append("algorithm source attribution is missing from package docs")
                break
        if "RBST" not in readme or "deterministic" not in rights:
            issues.append("DADS/LP93 source-description mismatch is not documented")
        for target in re.findall(r"\]\(([^)]+)\)", readme):
            if target.startswith(("http://", "https://", "#")):
                continue
            if not (PACKAGE / target.split("#", 1)[0]).resolve().is_file():
                issues.append(f"broken README target: {target}")
    return issues


static_issues = verify_workload
