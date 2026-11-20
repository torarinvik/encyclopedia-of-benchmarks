"""Static artifact and source inventory; deliberately does not build ports."""

from __future__ import annotations

import json
from pathlib import Path

from .verify_workload import workload_issues

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
ALGORITHM = "parameterized_pattern_matching_kmp"
EXPECTED_PORTS = {
    "c": "c/p/parameterized_pattern_matching_kmp.c",
    "c3": "c3/p/parameterized_pattern_matching_kmp.c3",
    "cpp": "cpp/p/parameterized_pattern_matching_kmp.cpp",
    "elisa": "elisa/p/parameterized_pattern_matching_kmp.elisa",
    "mojo": "mojo/p/parameterized_pattern_matching_kmp.mojo",
    "nim": "nim/p/parameterized_pattern_matching_kmp.nim",
    "odin": "odin/p/parameterized_pattern_matching_kmp.odin",
    "rust": "rust/p/parameterized_pattern_matching_kmp.rs",
    "v": "v/p/parameterized_pattern_matching_kmp.v",
    "zig": "zig/p/parameterized_pattern_matching_kmp.zig",
}
NULL_INPUT_GUARDS = {
    "c": "input == NULL",
    "c3": "input == null",
    "cpp": "input == nullptr",
    "elisa": "input.is_null()",
    "mojo": "UnsafePointer[Int64, ImmutAnyOrigin]()",
    "nim": "input.isNil",
    "odin": "input == nil",
    "rust": "input.is_null()",
    "v": "input == nil",
    "zig": "input_opt == null",
}


def static_issues() -> list[str]:
    issues = workload_issues()
    try:
        inventory = json.loads((PACKAGE / "inventory.json").read_text(encoding="utf-8"))
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read package inventory or README: {error}"]
    if (inventory.get("algorithm") != ALGORITHM
            or inventory.get("function_symbol") != ALGORITHM
            or inventory.get("abi") != "i64_array_bytes_output"):
        issues.append("inventory algorithm identity or ABI differs from the package")
    if inventory.get("native_paths") != EXPECTED_PORTS:
        issues.append("inventory language paths differ from the ten-port contract")
    bounds = inventory.get("bounds", {})
    if (bounds.get("maximum_valid_input_words") != 83
            or bounds.get("maximum_parseable_input_words") != 84
            or bounds.get("maximum_output_bytes") != 520
            or bounds.get("workspace_bytes") != 4096):
        issues.append("inventory bounds differ from the package contract")

    for language, relative in EXPECTED_PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} source: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if ALGORITHM not in source:
            issues.append(f"exported function name missing from {relative}")
        if NULL_INPUT_GUARDS[language] not in source:
            issues.append(f"null-input validation missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README source link missing for {language}")
    elisa = (ROOT / EXPECTED_PORTS["elisa"]).read_text(encoding="utf-8")
    if "*i64" in elisa or "UnsafePointer" in elisa:
        issues.append("Elisa should keep raw pointers at the exported boundary")

    for artifact in inventory.get("package_files", []):
        if not (PACKAGE / artifact).is_file():
            issues.append(f"missing package artifact: {artifact}")
    for reference in inventory.get("root_references", []):
        if not (ROOT / reference).is_file():
            issues.append(f"missing reference source: {reference}")
    for source_url in (
        "https://doi.org/10.1016/0020-0190(94)90086-8",
        "https://doi.org/10.1007/978-1-4939-2864-4_282",
    ):
        if source_url not in readme or source_url not in (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8"):
            issues.append(f"source citation missing from package docs: {source_url}")
    return issues


def check_inventory() -> list[str]:
    """Suite-facing alias for the source-only completeness report."""
    return static_issues()


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
