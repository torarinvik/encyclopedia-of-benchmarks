"""Package completeness helper for the shared byte-output suite; not run here."""
from __future__ import annotations

import json
from pathlib import Path

from .verify_workload import workload_issues

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "junta_test_partition_binary_search"
PORTS = {
    "c": "c/j/junta_test_partition_binary_search.c",
    "c3": "c3/j/junta_test_partition_binary_search.c3",
    "cpp": "cpp/j/junta_test_partition_binary_search.cpp",
    "elisa": "elisa/j/junta_test_partition_binary_search.elisa",
    "mojo": "mojo/j/junta_test_partition_binary_search.mojo",
    "nim": "nim/j/junta_test_partition_binary_search.nim",
    "odin": "odin/j/junta_test_partition_binary_search.odin",
    "rust": "rust/j/junta_test_partition_binary_search.rs",
    "v": "v/j/junta_test_partition_binary_search.v",
    "zig": "zig/j/junta_test_partition_binary_search.zig",
}
NULL_GUARDS = {
    "c": "input == NULL",
    "c3": "input == null",
    "cpp": "input == nullptr",
    "elisa": "input.is_null()",
    "mojo": "input == UnsafePointer[Int64, ImmutAnyOrigin]()",
    "nim": "input.isNil",
    "odin": "input == nil",
    "rust": "input.is_null()",
    "v": "isnil(input)",
    "zig": "input_opt == null",
}
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "inventory.json", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    "check_inventory.py", "__init__.py",
)


def static_issues() -> list[str]:
    issues = workload_issues()
    for name in REQUIRED:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    try:
        inventory = json.loads((PACKAGE / "inventory.json").read_text(encoding="utf-8"))
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read package metadata: {error}"]
    if inventory.get("algorithm") != SYMBOL:
        issues.append("inventory algorithm mismatch")
    if set(inventory.get("languages", {})) != set(PORTS):
        issues.append("inventory language set mismatch")
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if SYMBOL not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"input null guard missing from {relative}")
        if inventory["languages"].get(language) != relative:
            issues.append(f"inventory path mismatch for {language}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README port link missing for {language}")
    for source in (
        "https://www.cs.cmu.edu/~eblais/papers/TestingJuntas.pdf",
        "https://doi.org/10.1007/978-1-4939-2864-4_709",
    ):
        if source not in readme or source not in rights:
            issues.append(f"provenance source missing from README or RIGHTS: {source}")
    return issues


def check_inventory() -> list[str]:
    return static_issues()
