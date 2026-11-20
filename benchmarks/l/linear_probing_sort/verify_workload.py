"""Static contract, fixture, documentation, and ten-port inventory checks."""

from __future__ import annotations

import json
from pathlib import Path
import re

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "linear_probing_sort"
SOURCE_PATHS = (
    "c/l/linear_probing_sort.c",
    "c3/l/linear_probing_sort.c3",
    "cpp/l/linear_probing_sort.cpp",
    "elisa/l/linear_probing_sort.elisa",
    "mojo/l/linear_probing_sort.mojo",
    "nim/l/linear_probing_sort.nim",
    "odin/l/linear_probing_sort.odin",
    "rust/l/linear_probing_sort.rs",
    "v/l/linear_probing_sort.v",
    "zig/l/linear_probing_sort.zig",
)

try:
    from .independent_oracle import expected_result as independent_result
    from .primary_oracle import MAX_LENGTH, MAX_KEY, MIN_KEY, expected_result as primary_result
except ImportError:  # Direct invocation from the package directory.
    from independent_oracle import expected_result as independent_result  # type: ignore[no-redef]
    from primary_oracle import (MAX_LENGTH, MAX_KEY, MIN_KEY,
                                expected_result as primary_result)  # type: ignore[no-redef]


def verify_workload(workload: object | None = None) -> list[str]:
    issues: list[str] = []
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                 "primary_oracle.py", "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    if not (ROOT / "benchmarks/verify_linear_probing_sort.py").is_file():
        issues.append("missing sort-suite verifier")
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
    input_spec = workload.get("input")
    generation = input_spec.get("generation") if isinstance(input_spec, dict) else None
    profile = workload.get("profile")
    measurement = workload.get("measurement")
    source = workload.get("source")
    if not all(isinstance(value, dict) for value in (input_spec, generation, profile,
                                                     measurement, source)):
        return issues + ["workload sections must be objects"]
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or input_spec.get("kind") != "bounded_byte_key_array"
            or input_spec.get("lengths") != [0, 16, 64, 256, MAX_LENGTH]
            or input_spec.get("minimum_key") != MIN_KEY
            or input_spec.get("maximum_key") != MAX_KEY
            or generation.get("kind") != "modular_affine"
            or generation.get("multiplier") != 73
            or generation.get("modulus") != 256
            or generation.get("offset") != 0
            or profile.get("maximum_length") != MAX_LENGTH
            or profile.get("minimum_key") != MIN_KEY
            or profile.get("maximum_key") != MAX_KEY
            or profile.get("main_slots") != "m = 256 * (n + 1) + 1"
            or profile.get("overflow_slots") != "n"
            or profile.get("home_slot") != "floor((key - minimum) * (m - 1) / (maximum - minimum)); zero when all keys equal"
            or profile.get("maximum_workspace_bytes") != 2_107_400
            or profile.get("time_bound") != "O(m+n^2) worst case"
            or measurement.get("comparison_model") != "sort_call"
            or measurement.get("table_allocation_timed") is not True
            or source.get("url") != "https://xlinux.nist.gov/dads/HTML/linearProbingSort.html"):
        issues.append("workload identity, byte-key domain, table profile, or source differs")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing semantic workload cases"]
    seen: set[str] = set()
    for case in cases:
        if (not isinstance(case, dict) or not isinstance(case.get("id"), str)
                or not isinstance(case.get("input_values"), list)
                or not isinstance(case.get("expected_values"), list)):
            issues.append("invalid linear probing sort workload case")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate workload case: {case_id}")
        seen.add(case_id)
        values = case["input_values"]
        if len(values) > MAX_LENGTH or any(type(value) is not int or not MIN_KEY <= value <= MAX_KEY
                                           for value in values):
            issues.append(f"case is outside the bounded byte-key contract: {case_id}")
            continue
        expected = case["expected_values"]
        if primary_result(values) != expected or independent_result(values) != expected:
            issues.append(f"oracle fixture mismatch: {case_id}")
    if not {"empty", "singleton", "ascending", "descending", "all_equal",
            "overlapping_duplicate_runs", "sparse_key_collisions", "byte_extrema_repeated"} <= seen:
        issues.append("required semantic cases are missing")

    readme_path = PACKAGE / "README.md"
    rights_path = PACKAGE / "RIGHTS.md"
    if readme_path.is_file() and rights_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        rights = rights_path.read_text(encoding="utf-8")
        source_url = source.get("url")
        if not isinstance(source_url, str) or source_url not in readme or source_url not in rights:
            issues.append("algorithm source attribution is missing from package docs")
        for target in re.findall(r"\]\(([^)]+)\)", readme):
            if target.startswith(("http://", "https://", "#")):
                continue
            if not (PACKAGE / target.split("#", 1)[0]).resolve().is_file():
                issues.append(f"broken README target: {target}")
    return issues


static_issues = verify_workload
