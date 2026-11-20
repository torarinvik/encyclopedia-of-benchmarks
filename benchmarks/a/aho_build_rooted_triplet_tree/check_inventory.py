"""Static package completeness and provenance inventory for suite checks."""

from __future__ import annotations

import json
import importlib.util
from pathlib import Path
from types import ModuleType

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = {
    "c": "c/a/aho_build_rooted_triplet_tree.c",
    "c3": "c3/a/aho_build_rooted_triplet_tree.c3",
    "cpp": "cpp/a/aho_build_rooted_triplet_tree.cpp",
    "elisa": "elisa/a/aho_build_rooted_triplet_tree.elisa",
    "mojo": "mojo/a/aho_build_rooted_triplet_tree.mojo",
    "nim": "nim/a/aho_build_rooted_triplet_tree.nim",
    "odin": "odin/a/aho_build_rooted_triplet_tree.odin",
    "rust": "rust/a/aho_build_rooted_triplet_tree.rs",
    "v": "v/a/aho_build_rooted_triplet_tree.v",
    "zig": "zig/a/aho_build_rooted_triplet_tree.zig",
}
EXPECTED = {
    "README.md", "RIGHTS.md", "SOURCE_CROSSWALK.md", "INVENTORY.md",
    "INVENTORY.json", "workload.json", "primary_oracle.py",
    "independent_oracle.py", "verify_workload.py", "check_inventory.py",
    "__init__.py",
}
NULL_GUARDS = {
    "c": "input == NULL", "c3": "input == null", "cpp": "input == nullptr",
    "elisa": "input.is_null()", "mojo": "input == UnsafePointer[Int64, ImmutAnyOrigin]()",
    "nim": "input == nil", "odin": "input == nil", "rust": "input.is_null()",
    "v": "input == nil", "zig": "input == null",
}


def _load_module(name: str) -> ModuleType:
    spec = importlib.util.spec_from_file_location(name, PACKAGE / f"{name}.py")
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load package module {name}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package metadata: {error}"]
    if inventory.get("algorithm") != "aho_build_rooted_triplet_tree":
        issues.append("inventory algorithm mismatch")
    if inventory.get("function_symbol") != "aho_build_rooted_triplet_tree":
        issues.append("inventory function symbol mismatch")
    if inventory.get("abi") != "i64_array_bytes_output":
        issues.append("inventory ABI mismatch")
    if inventory.get("maximum_input_words") != 317 or inventory.get("maximum_parseable_words") != 318:
        issues.append("inventory input bounds mismatch")
    if inventory.get("maximum_output_bytes") != 112 or inventory.get("workspace_bytes") != 8192:
        issues.append("inventory output/workspace bound mismatch")
    if inventory.get("source_dois") != [
        "10.1137/0210030", "10.1007/978-1-4939-2864-4_92"
    ]:
        issues.append("inventory source citation list mismatch")
    if inventory.get("languages") != PORTS:
        issues.append("inventory language paths mismatch")
    if not EXPECTED.issubset(set(inventory.get("metadata", []))):
        issues.append("inventory metadata list incomplete")
    for filename in EXPECTED:
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package artifact: {filename}")
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if "aho_build_rooted_triplet_tree" not in source:
            issues.append(f"exported function text missing: {relative}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"null-input guard text missing: {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README path missing: {relative}")
    elisa_path = ROOT / PORTS["elisa"]
    if elisa_path.is_file():
        elisa = elisa_path.read_text(encoding="utf-8")
        if "view[i64]" not in elisa or "UnsafePointer" in elisa or "*i64" in elisa:
            issues.append("Elisa internals must use bounded views behind the ABI")
    for citation in ("https://doi.org/10.1137/0210030",
                     "https://doi.org/10.1007/978-1-4939-2864-4_92"):
        if citation not in readme or citation not in rights:
            issues.append(f"citation missing from README or RIGHTS: {citation}")
    if workload.get("algorithm") != "aho_build_rooted_triplet_tree":
        issues.append("workload identity mismatch")
    if (workload.get("function_symbol") != "aho_build_rooted_triplet_tree"
            or workload.get("abi") != "i64_array_bytes_output"):
        issues.append("workload symbol or ABI mismatch")
    if (workload.get("input", {}).get("maximum_valid_length") != 317
            or workload.get("input", {}).get("maximum_parseable_length") != 318):
        issues.append("workload input bounds mismatch")
    if workload.get("output", {}).get("maximum_output_bytes") != 112:
        issues.append("workload output bound mismatch")
    if workload.get("workspace", {}).get("bytes") != 8192:
        issues.append("workload workspace mismatch")
    if workload.get("input", {}).get("encoding") != "[n,q,(a,b,c)*q] where each triple means ab|c and the clustered pair is unordered":
        issues.append("workload input encoding mismatch")
    try:
        verifier = _load_module("verify_workload")
        issues.extend(verifier.workload_issues())
    except (OSError, ImportError, AttributeError, ValueError) as error:
        issues.append(f"workload review helper unavailable: {error}")
    return issues


def check_inventory() -> list[str]:
    """Suite-facing static inventory wrapper."""
    return static_issues()


def verify() -> None:
    issues = static_issues()
    if issues:
        raise ValueError("\n".join(issues))

