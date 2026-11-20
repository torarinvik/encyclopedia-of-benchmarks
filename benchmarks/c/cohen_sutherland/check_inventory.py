"""Static file, source-path, and workload-metadata inventory helper."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .verify_workload import workload_issues
except ImportError:
    from verify_workload import workload_issues  # type: ignore[no-redef]

ROOT = Path(__file__).resolve().parents[2]
PACKAGE = Path(__file__).resolve().parent
SYMBOL = "cohen_sutherland"
SOURCES = {
    "c": "c/c/cohen_sutherland.c",
    "c3": "c3/c/cohen_sutherland.c3",
    "cpp": "cpp/c/cohen_sutherland.cpp",
    "elisa": "elisa/c/cohen_sutherland.elisa",
    "mojo": "mojo/c/cohen_sutherland.mojo",
    "nim": "nim/c/cohen_sutherland.nim",
    "odin": "odin/c/cohen_sutherland.odin",
    "rust": "rust/c/cohen_sutherland.rs",
    "v": "v/c/cohen_sutherland.v",
    "zig": "zig/c/cohen_sutherland.zig",
}
NULL_GUARDS = {
    "c": "values == NULL",
    "c3": "values == null",
    "cpp": "values == nullptr",
    "elisa": "values == null",
    "mojo": "values == UnsafePointer[Int64, ImmutAnyOrigin]()",
    "nim": "values == nil",
    "odin": "values == nil",
    "rust": "values.is_null()",
    "v": "values == nil",
    "zig": "values == null",
}
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json",
    "workload.json", "independent_oracle.py", "verify_workload.py",
    "check_inventory.py", "__init__.py",
)
SOURCE_URLS = (
    "https://cim.mcgill.ca/~langer/557/6-slides-9pp.pdf",
    "https://www.cs.helsinki.fi/group/goa/viewing/leikkaus/uuu",
    "https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/lineclipping/CohenSutherland.java",
)


def static_issues() -> list[str]:
    issues = workload_issues()
    for filename in REQUIRED:
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package artifact: {filename}")
    if not (ROOT / "benchmarks/cohen_sutherland_oracle.py").is_file():
        issues.append("missing primary reference: benchmarks/cohen_sutherland_oracle.py")

    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read package metadata: {error}"]

    for language, relative in SOURCES.items():
        source_path = ROOT / relative
        if not source_path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        source = source_path.read_text(encoding="utf-8")
        if SYMBOL not in source:
            issues.append(f"ABI symbol missing from {relative}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"null-input check missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README source link missing for {language}")
        if language == "elisa":
            internals = source.split("export fn", 1)[0]
            if "UnsafePointer" in internals or "*i64" in internals:
                issues.append("Elisa should keep internal operations on borrowed views")

    expected_paths = set(SOURCES.values())
    if (inventory.get("algorithm") != SYMBOL
            or inventory.get("function_symbol") != SYMBOL
            or inventory.get("abi") != "i64_array_float64"
            or inventory.get("languages") != SOURCES):
        issues.append("inventory identity, ABI, or native path map is inconsistent")
    if workload.get("abi") != "i64_array_float64":
        issues.append("workload ABI differs from the scalar float64 contract")
    if (workload.get("input", {}).get("maximum_valid_input_length") != 9
            or workload.get("input", {}).get("maximum_parseable_input_length") != 10
            or workload.get("output", {}).get("maximum_elements") != 1
            or workload.get("workspace", {}).get("bytes") != 0):
        issues.append("workload bounds differ from the package contract")
    if len(expected_paths) != 10:
        issues.append("native path inventory does not contain ten distinct languages")
    for source_url in SOURCE_URLS:
        if source_url not in readme or source_url not in rights:
            issues.append(f"source provenance missing from README or RIGHTS: {source_url}")
    for target in (
        "../../cohen_sutherland_oracle.py", "independent_oracle.py", "workload.json",
        "verify_workload.py", "check_inventory.py", "INVENTORY.md", "INVENTORY.json",
    ):
        if target not in readme:
            issues.append(f"README is missing a package artifact link: {target}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
