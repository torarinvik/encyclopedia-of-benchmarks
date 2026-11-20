"""Static workload, source inventory, and oracle checks for Polyphase Merge Sort."""

from __future__ import annotations

import json
from pathlib import Path
import re

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "polyphase_merge_sort"
SOURCE_PATHS = (
    "c/p/polyphase_merge_sort.c",
    "c3/p/polyphase_merge_sort.c3",
    "cpp/p/polyphase_merge_sort.cpp",
    "elisa/p/polyphase_merge_sort.elisa",
    "mojo/p/polyphase_merge_sort.mojo",
    "nim/p/polyphase_merge_sort.nim",
    "odin/p/polyphase_merge_sort.odin",
    "rust/p/polyphase_merge_sort.rs",
    "v/p/polyphase_merge_sort.v",
    "zig/p/polyphase_merge_sort.zig",
)
NIST_URL = "https://xlinux.nist.gov/dads/HTML/polyphmrgsrt.html"
PRIMARY_URL = (
    "https://ftpmirror.your.org/pub/misc/bitsavers/pdf/ibm/technical_information_exchange/"
    "Z77-7257_Shores_-_System_360_Sorting_Techniques_19671003.pdf"
)

try:
    from .independent_oracle import expected_result as independent_result
    from .primary_oracle import (
        MAX_DUMMY_RUNS, MAX_INITIAL_RUNS, MAX_LENGTH, MAX_PHASES,
        MAX_RUN_DESCRIPTORS_PER_TAPE, MAX_INITIAL_TAPE_QUOTA,
        MAX_TOTAL_INITIAL_TAPE_SLOTS, MAX_WORKSPACE_BYTES, RUN_SIZE,
        expected_result as primary_result,
    )
except ImportError:  # Direct invocation from the package directory.
    from independent_oracle import expected_result as independent_result  # type: ignore[no-redef]
    from primary_oracle import (  # type: ignore[no-redef]
        MAX_DUMMY_RUNS, MAX_INITIAL_RUNS, MAX_LENGTH, MAX_PHASES,
        MAX_RUN_DESCRIPTORS_PER_TAPE, MAX_INITIAL_TAPE_QUOTA,
        MAX_TOTAL_INITIAL_TAPE_SLOTS, MAX_WORKSPACE_BYTES, RUN_SIZE,
        expected_result as primary_result,
    )


def verify_workload(workload: object | None = None) -> list[str]:
    issues: list[str] = []
    required = (
        "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
        "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    )
    for name in required:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    if not (ROOT / "benchmarks/verify_polyphase_merge_sort.py").is_file():
        issues.append("missing dedicated sort_call verifier")
    for source_path in SOURCE_PATHS:
        path = ROOT / source_path
        if not path.is_file():
            issues.append(f"missing language port: {source_path}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol in {source_path}")

    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload must be an object"]

    input_spec = workload.get("input", {})
    profile = workload.get("profile", {})
    generation = input_spec.get("generation", {}) if isinstance(input_spec, dict) else {}
    measurement = workload.get("measurement", {})
    source = workload.get("source", {})
    if not isinstance(input_spec, dict):
        input_spec = {}
    if not isinstance(profile, dict):
        profile = {}
    if not isinstance(generation, dict):
        generation = {}
    if not isinstance(measurement, dict):
        measurement = {}
    if not isinstance(source, dict):
        source = {}
    expected_lengths = [0, 1, 7, 8, 9, 16, 17, 24, 25, 32, 33, 64, 169, 256]
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "sort_call"
            or input_spec.get("kind") != "signed_i64_array"
            or input_spec.get("length_range") != [0, MAX_LENGTH]
            or input_spec.get("lengths") != expected_lengths
            or input_spec.get("input_modified") is not True
            or input_spec.get("sort_order") != "ascending"
            or generation.get("kind") != "modular_affine"
            or generation.get("multiplier") != 48271
            or generation.get("modulus") != 2000003
            or generation.get("offset") != 1000001
            or profile.get("maximum_length") != MAX_LENGTH
            or profile.get("minimum_value") != -(1 << 63)
            or profile.get("maximum_value") != (1 << 63) - 1
            or profile.get("stable") is not False
            or profile.get("initial_run_size") != RUN_SIZE
            or profile.get("maximum_initial_runs") != MAX_INITIAL_RUNS
            or profile.get("run_descriptor_slots_per_tape") != MAX_RUN_DESCRIPTORS_PER_TAPE
            or profile.get("maximum_initial_tape_quota") != MAX_INITIAL_TAPE_QUOTA
            or profile.get("maximum_total_initial_tape_slots") != MAX_TOTAL_INITIAL_TAPE_SLOTS
            or profile.get("maximum_dummy_runs") != MAX_DUMMY_RUNS
            or profile.get("maximum_merge_phases") != MAX_PHASES
            or profile.get("workspace_bytes") != MAX_WORKSPACE_BYTES
            or measurement.get("comparison_model") != "sort_call"
            or source.get("url") != NIST_URL
            or source.get("detailed_method_url") != PRIMARY_URL):
        issues.append("workload identity, source attribution, or bounded contract differs")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing semantic workload cases"]
    seen: set[str] = set()
    for case in cases:
        if (not isinstance(case, dict) or not isinstance(case.get("id"), str)
                or not isinstance(case.get("input_values"), list)
                or not isinstance(case.get("expected_values"), list)):
            issues.append("invalid Polyphase Merge Sort workload case")
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
        for url in (NIST_URL, PRIMARY_URL):
            if url not in readme or url not in rights:
                issues.append("algorithm source attribution is missing from package docs")
                break
        for target in re.findall(r"\]\(([^)]+)\)", readme):
            if target.startswith(("http://", "https://", "#")):
                continue
            local_target = (PACKAGE / target.split("#", 1)[0]).resolve()
            if not local_target.is_file():
                issues.append(f"broken README target: {target}")
    return issues


static_issues = verify_workload
