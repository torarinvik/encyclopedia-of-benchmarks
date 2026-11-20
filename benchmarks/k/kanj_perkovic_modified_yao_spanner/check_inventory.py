"""Static inventory checks for the ten source ports and package metadata."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "kanj_perkovic_modified_yao_spanner"
PORTS = {
    "c": "c/k/kanj_perkovic_modified_yao_spanner.c",
    "c3": "c3/k/kanj_perkovic_modified_yao_spanner.c3",
    "cpp": "cpp/k/kanj_perkovic_modified_yao_spanner.cpp",
    "elisa": "elisa/k/kanj_perkovic_modified_yao_spanner.elisa",
    "mojo": "mojo/k/kanj_perkovic_modified_yao_spanner.mojo",
    "nim": "nim/k/kanj_perkovic_modified_yao_spanner.nim",
    "odin": "odin/k/kanj_perkovic_modified_yao_spanner.odin",
    "rust": "rust/k/kanj_perkovic_modified_yao_spanner.rs",
    "v": "v/k/kanj_perkovic_modified_yao_spanner.v",
    "zig": "zig/k/kanj_perkovic_modified_yao_spanner.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
        inventory_md = (PACKAGE / "INVENTORY.md").read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package metadata: {error}"]
    if (inventory.get("algorithm") != SYMBOL
            or inventory.get("abi") != "i64_array_scalar"
            or inventory.get("function_symbol") != SYMBOL
            or inventory.get("maximum_valid_input_words") != 312
            or inventory.get("maximum_parseable_input_words") != 313
            or inventory.get("maximum_output_bytes") != 0
            or inventory.get("workspace_bytes") != 16384):
        issues.append("inventory identity or bounds differ")
    if set(inventory.get("sources", ())) != set(PORTS.values()):
        issues.append("inventory source list differs from ten ports")
    if workload.get("algorithm") != SYMBOL or workload.get("abi") != "i64_array_scalar":
        issues.append("workload identity or ABI differs")
    for title in ("Planar Geometric Spanners", "On Geometric Spanners of Euclidean and Unit Disk Graphs", "2.3, Figure 3"):
        if title not in readme or title not in rights:
            issues.append(f"provenance missing: {title}")
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing source: {relative}")
            continue
        try:
            source = path.read_text(encoding="utf-8")
        except OSError as error:
            issues.append(f"cannot read source {relative}: {error}")
            continue
        if SYMBOL not in source:
            issues.append(f"exported symbol absent: {relative}")
        if relative not in readme or relative not in inventory_md:
            issues.append(f"source link absent from docs: {relative}")
    for artifact in inventory.get("artifacts", []):
        if not (PACKAGE / artifact).is_file():
            issues.append(f"missing package artifact: {artifact}")
    return issues


def check_inventory() -> list[str]:
    return static_issues()
