"""Static file and source inventory helper for the SvS package."""
from __future__ import annotations

from pathlib import Path

try:
    from .verify_workload import workload_issues
except ImportError:
    from verify_workload import workload_issues

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SYMBOL = "inverted_list_svs_binary_search"
PORTS = {
    "c": "c/i/inverted_list_svs_binary_search.c",
    "c3": "c3/i/inverted_list_svs_binary_search.c3",
    "cpp": "cpp/i/inverted_list_svs_binary_search.cpp",
    "elisa": "elisa/i/inverted_list_svs_binary_search.elisa",
    "mojo": "mojo/i/inverted_list_svs_binary_search.mojo",
    "nim": "nim/i/inverted_list_svs_binary_search.nim",
    "odin": "odin/i/inverted_list_svs_binary_search.odin",
    "rust": "rust/i/inverted_list_svs_binary_search.rs",
    "v": "v/i/inverted_list_svs_binary_search.v",
    "zig": "zig/i/inverted_list_svs_binary_search.zig",
}
ARTIFACTS = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json", "workload.json",
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
            issues.append(f"README port link missing: {relative}")
    for source_url in (
        "https://doi.org/10.1007/978-1-4939-2864-4_628",
        "https://cs.uwaterloo.ca/~alopez-o/files/EoASIfTRS_2001.pdf",
    ):
        if source_url not in readme or source_url not in rights:
            issues.append(f"source URL absent from README or RIGHTS: {source_url}")
    elisa = (ROOT / PORTS["elisa"]).read_text(encoding="utf-8")
    if "UnsafePointer" in elisa or "*i64" in elisa:
        issues.append("Elisa should use bounded references/views inside the implementation")
    return issues


def check_inventory() -> list[str]:
    return static_issues()


if __name__ == "__main__":
    issues = static_issues()
    if issues:
        raise SystemExit("\n".join(issues))
    print("checked static SvS package inventory")
