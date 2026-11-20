"""Static workload, reference, documentation, and port inventory checks."""

from __future__ import annotations

import json
from pathlib import Path
import re

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "rectangle_union_area_sweep"
SOURCE_URL = "https://doi.org/10.1016/0196-6774(81)90027-4"
SOURCE_PATHS = (
    "c/g/rectangle_union_area_sweep.c",
    "c3/g/rectangle_union_area_sweep.c3",
    "cpp/g/rectangle_union_area_sweep.cpp",
    "elisa/g/rectangle_union_area_sweep.elisa",
    "mojo/g/rectangle_union_area_sweep.mojo",
    "nim/g/rectangle_union_area_sweep.nim",
    "odin/g/rectangle_union_area_sweep.odin",
    "rust/g/rectangle_union_area_sweep.rs",
    "v/g/rectangle_union_area_sweep.v",
    "zig/g/rectangle_union_area_sweep.zig",
)

try:
    from .independent_oracle import expected_result as independent_result
    from .primary_oracle import (
        MAX_AREA,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        MAX_WORKSPACE_BYTES,
        expected_result as primary_result,
        rectangles_from_input,
    )
except ImportError:  # Direct invocation from the package directory.
    from independent_oracle import expected_result as independent_result  # type: ignore[no-redef]
    from primary_oracle import (  # type: ignore[no-redef]
        MAX_AREA,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        MAX_WORKSPACE_BYTES,
        expected_result as primary_result,
        rectangles_from_input,
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
    output_spec = workload.get("output", {})
    workspace = workload.get("workspace", {})
    source_spec = workload.get("source", {})
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("workload identity or ABI differs")
    if (not isinstance(input_spec, dict)
            or input_spec.get("count_range") != [0, 64]
            or input_spec.get("coordinate_range") != [-1_000_000_000, 1_000_000_000]
            or input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_spec.get("input_modified") is not False
            or input_spec.get("invalid_input_result") != -1
            or input_spec.get("null_input_result") != -1):
        issues.append("input framing or bounds differ")
    if (not isinstance(output_spec, dict)
            or output_spec.get("kind") != "signed_64_bit_scalar"
            or output_spec.get("valid_result_range") != [0, MAX_AREA]
            or output_spec.get("invalid_input_result") != -1):
        issues.append("scalar output contract differs")
    if (not isinstance(workspace, dict)
            or workspace.get("bytes") != MAX_WORKSPACE_BYTES):
        issues.append("workspace metadata differs")
    if not isinstance(source_spec, dict) or source_spec.get("url") != SOURCE_URL:
        issues.append("pinned source metadata differs")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing workload cases"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid workload case")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate workload case: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        expected = case.get("expected_result")
        input_is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int
                or type(expected) is not int or type(input_is_null) is not bool):
            issues.append(f"invalid workload case fields: {case_id}")
            continue
        if primary_result(values, input_is_null, length) != expected:
            issues.append(f"primary oracle fixture mismatch: {case_id}")
            continue
        try:
            independent = independent_result(values, input_is_null, length)
        except ValueError:
            if rectangles_from_input(values, input_is_null, length) is None:
                issues.append(f"independent oracle rejected invalid fixture: {case_id}")
            continue
        if independent != expected:
            issues.append(f"independent oracle fixture mismatch: {case_id}")

    readme_path = PACKAGE / "README.md"
    rights_path = PACKAGE / "RIGHTS.md"
    if readme_path.is_file() and rights_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        rights = rights_path.read_text(encoding="utf-8")
        if SOURCE_URL not in readme or SOURCE_URL not in rights:
            issues.append("algorithm source attribution is missing from package docs")
        for target in re.findall(r"\]\(([^)]+)\)", readme):
            if target.startswith(("http://", "https://", "#")):
                continue
            if not (PACKAGE / target.split("#", 1)[0]).resolve().is_file():
                issues.append(f"broken README target: {target}")
    return issues


static_issues = verify_workload
