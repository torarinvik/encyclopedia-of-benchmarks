"""Static source, provenance, and workload inventory for this package."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
from types import ModuleType

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/p/perfect_phylogeny_three_state_2sat.c",
    "c3": "c3/p/perfect_phylogeny_three_state_2sat.c3",
    "cpp": "cpp/p/perfect_phylogeny_three_state_2sat.cpp",
    "elisa": "elisa/p/perfect_phylogeny_three_state_2sat.elisa",
    "mojo": "mojo/p/perfect_phylogeny_three_state_2sat.mojo",
    "nim": "nim/p/perfect_phylogeny_three_state_2sat.nim",
    "odin": "odin/p/perfect_phylogeny_three_state_2sat.odin",
    "rust": "rust/p/perfect_phylogeny_three_state_2sat.rs",
    "v": "v/p/perfect_phylogeny_three_state_2sat.v",
    "zig": "zig/p/perfect_phylogeny_three_state_2sat.zig",
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
    "v": "input == nil",
    "zig": "input_ptr orelse return -1",
}
EXPECTED_FILES = {
    "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    "check_inventory.py", "SOURCE_CROSSWALK.md", "__init__.py",
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
    primary = _load_module("primary_oracle")
    verifier = _load_module("verify_workload")

    if (inventory.get("algorithm") != "perfect_phylogeny_three_state_2sat"
            or inventory.get("function_symbol") != "perfect_phylogeny_three_state_2sat"
            or inventory.get("abi") != "i64_array_scalar"
            or inventory.get("workspace_bytes") != primary.WORKSPACE_BYTES):
        issues.append("inventory identity, ABI, or workspace mismatch")
    if (workload.get("function_symbol") != "perfect_phylogeny_three_state_2sat"
            or workload.get("output", {}).get("valid_result_range") != [0, 1]
            or workload.get("output", {}).get("invalid_input_result") != -1):
        issues.append("workload symbol or scalar result contract mismatch")
    if ("missing_state_extension" not in workload.get("contract", {})
            or not isinstance(workload.get("complexity"), dict)):
        issues.append("workload extension or complexity metadata is missing")
    input_spec = workload.get("input", {})
    if (input_spec.get("maximum_valid_length") != primary.MAX_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != primary.MAX_PARSEABLE_INPUT_LENGTH
            or input_spec.get("zero_characters") is None):
        issues.append("workload input bounds differ from the primary reference")
    if workload.get("workspace", {}).get("bytes") != primary.WORKSPACE_BYTES:
        issues.append("workload workspace differs from the primary reference")
    if (inventory.get("maximum_input_words") != primary.MAX_INPUT_LENGTH
            or inventory.get("maximum_parseable_words") != primary.MAX_PARSEABLE_INPUT_LENGTH):
        issues.append("inventory input bounds differ from the primary reference")
    if inventory.get("clause_bound") != 284 or inventory.get("implication_arc_bound") != 568:
        issues.append("inventory formula bounds differ from the bounded extension")
    if inventory.get("source_dois") != [
        "10.1007/978-1-4939-2864-4_288", "10.4310/CIS.2009.v9.n4.a1"
    ]:
        issues.append("inventory source list differs from the reviewed crosswalk")
    if inventory.get("languages") != PORTS:
        issues.append("inventory language set differs from the ten-port contract")
    if not EXPECTED_FILES.issubset(set(inventory.get("metadata", []))):
        issues.append("inventory metadata list is incomplete")
    for filename in EXPECTED_FILES:
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package artifact: {filename}")
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} language source: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if "perfect_phylogeny_three_state_2sat" not in source:
            issues.append(f"exported symbol text missing: {relative}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"null-input guard missing: {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README source link missing: {language}")
    elisa = (ROOT / PORTS["elisa"]).read_text(encoding="utf-8") if (ROOT / PORTS["elisa"]).is_file() else ""
    if "view[i64]" not in elisa or "UnsafePointer" in elisa or "*i64" in elisa:
        issues.append("Elisa must convert the ABI input to a bounded view")
    for citation in (
        "https://doi.org/10.1007/978-1-4939-2864-4_288",
        "https://doi.org/10.4310/CIS.2009.v9.n4.a1",
    ):
        if citation not in readme or citation not in rights:
            issues.append(f"source citation missing from README or RIGHTS: {citation}")
    try:
        issues.extend(verifier.workload_issues())
    except (OSError, ImportError, AttributeError, ValueError) as error:
        issues.append(f"workload review helper failed to load: {error}")
    return issues


def verify() -> None:
    issues = static_issues()
    if issues:
        raise ValueError("\n".join(issues))
