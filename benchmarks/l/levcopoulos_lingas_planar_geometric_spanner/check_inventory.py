"""Static package/source/workload inventory; intentionally not run here."""
from __future__ import annotations

import json
import re
from pathlib import Path

try:
    from .independent_oracle import expected_output as independent
    from .primary_oracle import (
        MAX_EDGES, MAX_N, MAX_OUTPUT_BYTES, MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH, expected_output as primary,
    )
except ImportError:  # Direct invocation from the package directory.
    from independent_oracle import expected_output as independent  # type: ignore[no-redef]
    from primary_oracle import (  # type: ignore[no-redef]
        MAX_EDGES, MAX_N, MAX_OUTPUT_BYTES, MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH, expected_output as primary,
    )

PACKAGE = Path(__file__).resolve().parent
REPO_ROOT = PACKAGE.parents[2]
NAME = "levcopoulos_lingas_planar_geometric_spanner"
LANGUAGES = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
LANGUAGE_NAMES = {
    "c": "C", "c3": "C3", "cpp": "C++", "elisa": "Elisa",
    "mojo": "Mojo", "nim": "Nim", "odin": "Odin", "rust": "Rust",
    "v": "V", "zig": "Zig",
}
REQUIRED_CASES = {
    "triangle_mst_no_interior_face", "convex_quadrilateral_no_absorption",
    "interior_point_absorbs_exposed_face", "carried_path_triggers_retained_shortcut",
    "duplicate_delaunay_edge",
    "collinear_points_rejected", "null_input", "null_output",
    "short_output_capacity", "invalid_before_null_output",
}
REQUIRED_CASE_ORDER = [
    "triangle_mst_no_interior_face",
    "convex_quadrilateral_no_absorption",
    "interior_point_absorbs_exposed_face",
    "carried_path_triggers_retained_shortcut",
    "duplicate_delaunay_edge",
    "collinear_points_rejected",
    "null_input",
    "null_output",
    "short_output_capacity",
    "invalid_before_null_output",
]


def _inventory_issues() -> list[str]:
    path = PACKAGE / "inventory.json"
    try:
        inventory = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        return [f"cannot read inventory.json: {error}"]
    if not isinstance(inventory, dict):
        return ["inventory.json must be an object"]
    issues: list[str] = []
    if (inventory.get("algorithm") != NAME
            or inventory.get("abi") != "i64_array_bytes_output"
            or inventory.get("fixed_workspace_bytes_upper_bound") != 8192):
        issues.append("inventory identity, ABI, or workspace mismatch")
    actual_languages = inventory.get("languages")
    expected_languages = [
        {
            "name": LANGUAGE_NAMES[language],
            "path": f"{language}/l/{NAME}.{extension}",
            "symbol": NAME,
        }
        for language, extension in LANGUAGES.items()
    ]
    if actual_languages != expected_languages:
        issues.append("inventory language paths/symbols do not match the ten ports")
    expected_workload = {
        "path": f"benchmarks/l/{NAME}/workload.json",
        "case_ids": REQUIRED_CASE_ORDER,
    }
    actual_workload = inventory.get("workload")
    if (not isinstance(actual_workload, dict)
            or actual_workload.get("path") != expected_workload["path"]
            or actual_workload.get("case_ids") != expected_workload["case_ids"]):
        issues.append("inventory workload path/fixture IDs mismatch")
    return issues


def static_issues(workload: object | None = None) -> list[str]:
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, ValueError) as error:
            return [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    issues: list[str] = []
    input_meta, output_meta, source = workload.get("input"), workload.get("output"), workload.get("source")
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != NAME
            or workload.get("function_symbol") != NAME
            or workload.get("abi") != "i64_array_bytes_output"
            or not isinstance(input_meta, dict)
            or input_meta.get("encoding") != "[n, x0, y0, ..., x(n-1), y(n-1), m, (u,v)*m]"
            or input_meta.get("n_range") != [3, MAX_N]
            or input_meta.get("m_range") != [3, MAX_EDGES]
            or input_meta.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_meta.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or not isinstance(output_meta, dict)
            or output_meta.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or output_meta.get("no_write_on_error") is not True
            or output_meta.get("error_precedence") !=
            "Input and Delaunay validation precede output pointer and capacity checks."):
        issues.append("identity, bounds, or output contract mismatch")
    if (not isinstance(source, dict)
            or source.get("url") != "https://doi.org/10.1007/BF01758846"
            or source.get("chapter_url") != "https://doi.org/10.1007/978-1-4939-2864-4_294"
            or source.get("algorithm_attribution") != "Algorithm 3.1, §§2-3"
            or not isinstance(source.get("implementation_status"), str)
            or "clean-room" not in source.get("implementation_status", "")):
        issues.append("source attribution mismatch")

    issues.extend(_inventory_issues())

    for language, extension in LANGUAGES.items():
        path = REPO_ROOT / language / "l" / f"{NAME}.{extension}"
        if not path.is_file():
            issues.append(f"missing language port: {language}")
        elif NAME not in path.read_text(encoding="utf-8"):
            issues.append(f"exported symbol missing from: {language}")
    for filename in ("README.md", "RIGHTS.md", "INVENTORY.md", "inventory.json",
                     "check_inventory.py", "workload.json", "primary_oracle.py",
                     "independent_oracle.py"):
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package artifact: {filename}")

    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        for language, extension in LANGUAGES.items():
            target = f"../../../{language}/l/{NAME}.{extension}"
            if f"]({target})" not in readme:
                issues.append(f"README port target missing: {language}")
        for target in re.findall(r"\]\(([^)]+)\)", readme):
            if target.startswith(("http://", "https://", "#")):
                continue
            if not (PACKAGE / target).resolve().is_file():
                issues.append(f"README local target does not resolve: {target}")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["fixture cases are missing"]
    seen: set[str] = set()
    case_order: list[str] = []
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("malformed fixture record")
            continue
        case_id = case["id"]
        case_order.append(case_id)
        if case_id in seen:
            issues.append(f"duplicate fixture id: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length", len(values) if isinstance(values, list) else -1)
        capacity = case.get("output_capacity")
        input_null, output_null = case.get("input_is_null", False), case.get("output_is_null", False)
        if (not isinstance(values, list)
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
                or type(length) is not int or not 0 <= length <= MAX_PARSEABLE_INPUT_LENGTH
                or type(input_null) is not bool or type(output_null) is not bool
                or input_null and values
                or not input_null and length != len(values)
                or capacity is not None and (type(capacity) is not int or capacity < 0)):
            issues.append(f"invalid fixture framing: {case_id}")
            continue
        try:
            expected = case["expected_result"], bytes.fromhex(case["expected_output_hex"])
        except (KeyError, TypeError, ValueError):
            issues.append(f"invalid expected output: {case_id}")
            continue
        args = (values, capacity, output_null, input_null, length)
        if type(expected[0]) is not int or primary(*args) != expected or independent(*args) != expected:
            issues.append(f"oracle/fixture disagreement: {case_id}")
    if seen != REQUIRED_CASES or case_order != REQUIRED_CASE_ORDER:
        issues.append("fixture inventory mismatch")
    return issues


def verify(workload: object | None = None) -> bool:
    issues = static_issues(workload)
    if issues:
        raise ValueError("; ".join(issues))
    return True
