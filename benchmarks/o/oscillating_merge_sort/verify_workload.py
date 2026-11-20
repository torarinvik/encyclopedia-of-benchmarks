"""Static workload, oracle, provenance, verifier, and ten-port checks."""

from __future__ import annotations

import json
from pathlib import Path
import re

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "oscillating_merge_sort"
SOURCE_URL = "https://xlinux.nist.gov/dads/HTML/oscillatingMergeSort.html"
DOI_URL = "https://doi.org/10.1145/321127.321133"
SOURCE_PATHS = (
    "c/o/oscillating_merge_sort.c",
    "c3/o/oscillating_merge_sort.c3",
    "cpp/o/oscillating_merge_sort.cpp",
    "elisa/o/oscillating_merge_sort.elisa",
    "mojo/o/oscillating_merge_sort.mojo",
    "nim/o/oscillating_merge_sort.nim",
    "odin/o/oscillating_merge_sort.odin",
    "rust/o/oscillating_merge_sort.rs",
    "v/o/oscillating_merge_sort.v",
    "zig/o/oscillating_merge_sort.zig",
)

try:
    from .independent_oracle import expected_result as independent_result
    from .primary_oracle import (
        INITIAL_RUN_SIZE, MAX_LENGTH, MAX_WORKSPACE_BYTES, MERGE_INPUTS,
        TOTAL_TAPES, expected_result as primary_result,
    )
except ImportError:  # Direct invocation from the package directory.
    from independent_oracle import expected_result as independent_result  # type: ignore[no-redef]
    from primary_oracle import (  # type: ignore[no-redef]
        INITIAL_RUN_SIZE, MAX_LENGTH, MAX_WORKSPACE_BYTES, MERGE_INPUTS,
        TOTAL_TAPES, expected_result as primary_result,
    )


def verify_workload(workload: object | None = None) -> list[str]:
    issues: list[str] = []
    package_files = (
        "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
        "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    )
    for name in package_files:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    custom_verifier = ROOT / "benchmarks/verify_oscillating_merge_sort.py"
    if not custom_verifier.is_file():
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
    input_spec = workload.get("input", {})
    profile = workload.get("profile", {})
    measurement = workload.get("measurement", {})
    source = workload.get("source", {})
    if not isinstance(input_spec, dict): input_spec = {}
    if not isinstance(profile, dict): profile = {}
    if not isinstance(measurement, dict): measurement = {}
    if not isinstance(source, dict): source = {}
    generation = input_spec.get("generation", {})
    if not isinstance(generation, dict): generation = {}
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "mutable_i64_array"
            or input_spec.get("kind") != "signed_i64_array"
            or input_spec.get("lengths") != [0, 16, 256, MAX_LENGTH]
            or generation.get("kind") != "modular_affine"
            or generation.get("multiplier") != 48271
            or generation.get("modulus") != 2000003
            or generation.get("offset") != 1000001
            or profile.get("maximum_length") != MAX_LENGTH
            or profile.get("total_tape_count") != TOTAL_TAPES
            or profile.get("merge_input_tapes") != MERGE_INPUTS
            or profile.get("initial_run_size") != INITIAL_RUN_SIZE
            or profile.get("workspace_bytes") != MAX_WORKSPACE_BYTES
            or measurement.get("comparison_model") != "sort_call"
            or source.get("url") != SOURCE_URL
            or source.get("primary_reference_url") != DOI_URL):
        issues.append("sort_call identity, bounded profile, or source metadata differs")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing semantic workload cases"]
    seen: set[str] = set()
    for case in cases:
        if (not isinstance(case, dict) or not isinstance(case.get("id"), str)
                or not isinstance(case.get("input_values"), list)
                or not isinstance(case.get("expected_values"), list)):
            issues.append("invalid semantic workload case")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate workload case: {case_id}")
        seen.add(case_id)
        values, expected = case["input_values"], case["expected_values"]
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
        if any(url not in readme or url not in rights for url in (SOURCE_URL, DOI_URL)):
            issues.append("algorithm source attribution is missing from package docs")
        for target in re.findall(r"\]\(([^)]+)\)", readme):
            if target.startswith(("http://", "https://", "#")):
                continue
            if not (PACKAGE / target.split("#", 1)[0]).resolve().is_file():
                issues.append(f"broken README target: {target}")
    return issues


static_issues = verify_workload
