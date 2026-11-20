"""Static package and ten-port inventory for suffix-tray pattern query."""

from __future__ import annotations

from pathlib import Path

try:
    from .verify_workload import workload_issues
except ImportError:
    from verify_workload import workload_issues

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SYMBOL = "suffix_tray_pattern_query"
PORTS = {
    "c": "c/s/suffix_tray_pattern_query.c",
    "c3": "c3/s/suffix_tray_pattern_query.c3",
    "cpp": "cpp/s/suffix_tray_pattern_query.cpp",
    "elisa": "elisa/s/suffix_tray_pattern_query.elisa",
    "mojo": "mojo/s/suffix_tray_pattern_query.mojo",
    "nim": "nim/s/suffix_tray_pattern_query.nim",
    "odin": "odin/s/suffix_tray_pattern_query.odin",
    "rust": "rust/s/suffix_tray_pattern_query.rs",
    "v": "v/s/suffix_tray_pattern_query.v",
    "zig": "zig/s/suffix_tray_pattern_query.zig",
}
ARTIFACTS = (
    "__init__.py", "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py", "check_inventory.py",
)


def static_issues() -> list[str]:
    issues = workload_issues()
    for name in ARTIFACTS:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    for relative in PORTS.values():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing port: {relative}")
            continue
        if SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"entrypoint missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README link missing: {relative}")
    for source_url in (
        "https://doi.org/10.1007/11786986_32",
        "https://doi.org/10.1007/978-1-4939-2864-4_422",
    ):
        if source_url not in readme or source_url not in rights:
            issues.append(f"source URL absent from README or RIGHTS: {source_url}")
    elisa = ROOT / PORTS["elisa"]
    if elisa.is_file():
        source = elisa.read_text(encoding="utf-8")
        if "UnsafePointer" in source or "*i64" in source:
            issues.append("Elisa should use bounded references/views inside the implementation")
    return issues


def check_inventory() -> list[str]:
    return static_issues()


if __name__ == "__main__":
    issues = static_issues()
    if issues:
        raise SystemExit("\n".join(issues))
    print("checked static suffix-tray package inventory")
