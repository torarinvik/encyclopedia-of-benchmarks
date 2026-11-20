"""Static workload and source-inventory checks for UnShuffle sort."""

from __future__ import annotations

import json
from pathlib import Path
import re

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "unshuffle_sort"
MAX_LENGTH = 1024
SOURCE_PATHS = (
    "c/u/unshuffle_sort.c",
    "c3/u/unshuffle_sort.c3",
    "cpp/u/unshuffle_sort.cpp",
    "elisa/u/unshuffle_sort.elisa",
    "mojo/u/unshuffle_sort.mojo",
    "nim/u/unshuffle_sort.nim",
    "odin/u/unshuffle_sort.odin",
    "rust/u/unshuffle_sort.rs",
    "v/u/unshuffle_sort.v",
    "zig/u/unshuffle_sort.zig",
)

try:
    from .independent_oracle import expected_result as independent_result
    from .primary_oracle import expected_result as primary_result
except ImportError:  # Direct invocation from the package directory.
    from independent_oracle import expected_result as independent_result  # type: ignore[no-redef]
    from primary_oracle import expected_result as primary_result  # type: ignore[no-redef]


def verify_workload(workload: object | None = None) -> list[str]:
    issues: list[str] = []
    required = (
        "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
        "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    )
    for name in required:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    if not (ROOT / "benchmarks/verify_unshuffle_sort.py").is_file():
        issues.append("missing custom sort_call verifier")
    for source in SOURCE_PATHS:
        path = ROOT / source
        if not path.is_file():
            issues.append(f"missing port: {source}")
        else:
            contents = path.read_text(encoding="utf-8")
            if SYMBOL not in contents:
                issues.append(f"missing exported symbol in {source}")
            if "scratch" not in contents:
                issues.append(f"missing caller-provided scratch buffer in {source}")

    inventory_path = PACKAGE / "INVENTORY.md"
    if inventory_path.is_file():
        inventory = inventory_path.read_text(encoding="utf-8")
        for source in SOURCE_PATHS:
            if source not in inventory:
                issues.append(f"inventory omits source path: {source}")
        if "Pending" in inventory:
            issues.append("language inventory still has pending ports")
    readme_path = PACKAGE / "README.md"
    rights_path = PACKAGE / "RIGHTS.md"
    if readme_path.is_file() and rights_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        rights = rights_path.read_text(encoding="utf-8")
        if ("https://xlinux.nist.gov/dads/HTML/unshufflsort.html" not in readme
                or "https://xlinux.nist.gov/dads/HTML/unshufflsort.html" not in rights
                or "Art S. Kagel" not in rights):
            issues.append("algorithm source attribution is missing from package docs")

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
    if not isinstance(input_spec, dict):
        input_spec = {}
    if not isinstance(profile, dict):
        profile = {}
    if not isinstance(measurement, dict):
        measurement = {}
    if not isinstance(source, dict):
        source = {}
    generation = input_spec.get("generation", {})
    if not isinstance(generation, dict):
        generation = {}
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "mutable_i64_with_scratch"
            or input_spec.get("kind") != "signed_i64_array"
            or input_spec.get("lengths") != [0, 1, 16, 256, MAX_LENGTH]
            or generation.get("kind") != "modular_affine"
            or generation.get("multiplier") != 48271
            or generation.get("modulus") != 2000003
            or generation.get("offset") != 1000001
            or workload.get("maximum_length") != MAX_LENGTH
            or workload.get("scratch_elements_extra") != 0
            or profile.get("pile_selection")
            != "first pile that accepts at an endpoint; prefer the front when both endpoints accept"
            or profile.get("pile_order") != "nondecreasing from front to back"
            or profile.get("merge") != "min-heap over the current front of every pile, ties by pile index"
            or profile.get("stable") is not False
            or profile.get("maximum_workspace_bytes") != 28672
            or measurement.get("comparison_model") != "sort_call"
            or source.get("url") != "https://xlinux.nist.gov/dads/HTML/unshufflsort.html"
            or source.get("primary_reference") != "Art S. Kagel, Unshuffle Algorithm, Not Quite a Sort?, Computer Language 3(11), November 1985"):
        issues.append("workload identity, source, ABI, or profile differs")

    for name in ("README.md", "RIGHTS.md"):
        path = PACKAGE / name
        if path.is_file():
            contents = path.read_text(encoding="utf-8")
            for url in (
                "https://xlinux.nist.gov/dads/HTML/unshufflsort.html",
                "Art S. Kagel",
            ):
                if url not in contents:
                    issues.append(f"source attribution missing from {name}")
                    break
    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        for target in re.findall(r"\]\(([^)]+)\)", readme):
            if target.startswith(("http://", "https://", "#")):
                continue
            if not (PACKAGE / target.split("#", 1)[0]).resolve().is_file():
                issues.append(f"broken README target: {target}")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing semantic workload cases"]
    seen: set[str] = set()
    for case in cases:
        if (not isinstance(case, dict) or not isinstance(case.get("id"), str)
                or not isinstance(case.get("input_values"), list)
                or not isinstance(case.get("expected_values"), list)):
            issues.append("invalid UnShuffle sort workload case")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate workload case: {case_id}")
        seen.add(case_id)
        values = case["input_values"]
        expected = case["expected_values"]
        if (len(values) > MAX_LENGTH
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                       for value in values)
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                       for value in expected)):
            issues.append(f"invalid input values: {case_id}")
            continue
        try:
            if primary_result(values) != expected or independent_result(values) != expected:
                issues.append(f"oracle fixture mismatch: {case_id}")
        except (TypeError, ValueError):
            issues.append(f"invalid oracle input: {case_id}")
    return issues


static_issues = verify_workload
