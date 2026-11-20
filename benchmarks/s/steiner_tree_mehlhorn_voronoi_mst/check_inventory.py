"""Static package inventory checker; not executed during source drafting."""
from __future__ import annotations

import json
from pathlib import Path

from .verify_workload import workload_issues

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "steiner_tree_mehlhorn_voronoi_mst"
PORTS = {
    "c": "c/s/steiner_tree_mehlhorn_voronoi_mst.c",
    "c3": "c3/s/steiner_tree_mehlhorn_voronoi_mst.c3",
    "cpp": "cpp/s/steiner_tree_mehlhorn_voronoi_mst.cpp",
    "elisa": "elisa/s/steiner_tree_mehlhorn_voronoi_mst.elisa",
    "mojo": "mojo/s/steiner_tree_mehlhorn_voronoi_mst.mojo",
    "nim": "nim/s/steiner_tree_mehlhorn_voronoi_mst.nim",
    "odin": "odin/s/steiner_tree_mehlhorn_voronoi_mst.odin",
    "rust": "rust/s/steiner_tree_mehlhorn_voronoi_mst.rs",
    "v": "v/s/steiner_tree_mehlhorn_voronoi_mst.v",
    "zig": "zig/s/steiner_tree_mehlhorn_voronoi_mst.zig",
}
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json", "inventory.json",
    "workload.json", "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    "check_inventory.py", "__init__.py",
)


def static_issues() -> list[str]:
    issues = workload_issues()
    for name in REQUIRED:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing artifact: {name}")
    try:
        inventory = json.loads((PACKAGE / "inventory.json").read_text(encoding="utf-8"))
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read package metadata: {error}"]
    if inventory.get("algorithm") != SYMBOL:
        issues.append("inventory algorithm mismatch")
    if set(inventory.get("language_ports", {})) != set(PORTS):
        issues.append("inventory language set mismatch")
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} source: {relative}")
            continue
        if SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"exported symbol text missing from {relative}")
        if inventory["language_ports"].get(language) != relative:
            issues.append(f"inventory path mismatch for {language}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README link missing for {language}")
    for doi in (
        "https://doi.org/10.1016/0020-0190(88)90066-X",
        "https://doi.org/10.1007/978-1-4939-2864-4_403",
    ):
        if doi not in readme or doi not in rights:
            issues.append(f"source DOI absent from README or RIGHTS: {doi}")
    if "steiner_tree_subset_dp" not in readme or "steiner_tree_gain_greedy" not in readme:
        issues.append("duplicate rationale missing local package comparisons")
    return issues


def check_inventory() -> list[str]:
    return static_issues()
