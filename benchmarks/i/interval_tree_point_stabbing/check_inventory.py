"""Static package-file and provenance inventory for interval point stabbing."""
from __future__ import annotations

import json
from pathlib import Path

try:
    from .primary_oracle import MAX_OUTPUT_BYTES
    from .verify_workload import workload_issues
except ImportError:
    from primary_oracle import MAX_OUTPUT_BYTES
    from verify_workload import workload_issues

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SYMBOL = "interval_tree_point_stabbing"
PORTS = {
    "c": "c/i/interval_tree_point_stabbing.c",
    "c3": "c3/i/interval_tree_point_stabbing.c3",
    "cpp": "cpp/i/interval_tree_point_stabbing.cpp",
    "elisa": "elisa/i/interval_tree_point_stabbing.elisa",
    "mojo": "mojo/i/interval_tree_point_stabbing.mojo",
    "nim": "nim/i/interval_tree_point_stabbing.nim",
    "odin": "odin/i/interval_tree_point_stabbing.odin",
    "rust": "rust/i/interval_tree_point_stabbing.rs",
    "v": "v/i/interval_tree_point_stabbing.v",
    "zig": "zig/i/interval_tree_point_stabbing.zig",
}
ARTIFACTS = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py", "check_inventory.py",
)
SOURCE_URLS = (
    "https://mitpress.mit.edu/9780262046305/introduction-to-algorithms/",
    "https://xlinux.nist.gov/dads/HTML/intervaltree.html",
)


def static_issues() -> list[str]:
    issues = workload_issues()
    for artifact in ARTIFACTS:
        if not (PACKAGE / artifact).is_file():
            issues.append(f"missing package artifact: {artifact}")
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read inventory: {error}"]
    if inventory.get("algorithm") != SYMBOL or inventory.get("abi") != "i64_array_bytes_output":
        issues.append("inventory identity or ABI mismatch")
    if inventory.get("ports") != PORTS:
        issues.append("inventory language paths differ from the expected ten-port map")
    if inventory.get("bounds") != {
        "maximum_valid_input_words": 42,
        "maximum_parseable_input_words": 43,
        "maximum_output_bytes": MAX_OUTPUT_BYTES,
        "workspace_bytes": 4096,
    }:
        issues.append("inventory bounds differ from the package contract")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if "does not benchmark red-black rotations, insertion, or deletion" not in readme:
        issues.append("README must preserve the static-profile scope caveat")
    for relative in PORTS.values():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing native source: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if SYMBOL not in source:
            issues.append(f"entrypoint missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README link missing: {relative}")
    for url in SOURCE_URLS:
        if url not in readme or url not in rights:
            issues.append(f"source citation missing from README or RIGHTS: {url}")
    elisa = (ROOT / PORTS["elisa"]).read_text(encoding="utf-8") if (ROOT / PORTS["elisa"]).is_file() else ""
    if "UnsafePointer" in elisa or "*i64" in elisa:
        issues.append("Elisa implementation should use bounded views internally")
    return issues


def check_inventory() -> list[str]:
    return static_issues()


if __name__ == "__main__":
    issues = static_issues()
    if issues:
        raise SystemExit("\n".join(issues))
    print("static interval-tree inventory")
