"""Static package inventory and provenance checks for the bounded PEIBFS profile."""

from __future__ import annotations

import json
import re
from pathlib import Path

from benchmarks.e.eibfs_bottom_up_graph_cut_merging.verify_workload import verify as verify_workload

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/e/eibfs_bottom_up_graph_cut_merging"
PORTS = {
    "c": ROOT / "c/e/eibfs_bottom_up_graph_cut_merging.c",
    "c3": ROOT / "c3/e/eibfs_bottom_up_graph_cut_merging.c3",
    "cpp": ROOT / "cpp/e/eibfs_bottom_up_graph_cut_merging.cpp",
    "elisa": ROOT / "elisa/e/eibfs_bottom_up_graph_cut_merging.elisa",
    "mojo": ROOT / "mojo/e/eibfs_bottom_up_graph_cut_merging.mojo",
    "nim": ROOT / "nim/e/eibfs_bottom_up_graph_cut_merging.nim",
    "odin": ROOT / "odin/e/eibfs_bottom_up_graph_cut_merging.odin",
    "rust": ROOT / "rust/e/eibfs_bottom_up_graph_cut_merging.rs",
    "v": ROOT / "v/e/eibfs_bottom_up_graph_cut_merging.v",
    "zig": ROOT / "zig/e/eibfs_bottom_up_graph_cut_merging.zig",
}
NULL_GUARDS = {
    "c": "input == NULL",
    "c3": "input==null",
    "cpp": "input == nullptr",
    "elisa": "input.is_null()",
    "mojo": "input == UnsafePointer[Int64, ImmutAnyOrigin]()",
    "nim": "input.isNil",
    "odin": "input == nil",
    "rust": "input.is_null()",
    "v": "input == nil",
    "zig": "input_opt == null",
}
SOURCES = (
    "https://doi.org/10.1109/CVPR.2010.5539898",
    "https://www.microsoft.com/en-us/research/wp-content/uploads/2016/11/ghkktw_ESA2015.pdf",
    "https://github.com/fcBK-maxflow/fcBK-benchmark",
)


def static_issues() -> list[str]:
    issues = verify_workload()
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read workload: {error}"]
    if workload.get("algorithm") != "eibfs_bottom_up_graph_cut_merging":
        issues.append("algorithm ID mismatch")
    for source in SOURCES:
        if source not in (PACKAGE / "README.md").read_text(encoding="utf-8"):
            issues.append(f"README missing provenance source: {source}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for target in re.findall(r"\]\(([^)]+)\)", readme):
        if target.startswith(("https://", "http://", "#")):
            continue
        if not (PACKAGE / target).resolve().is_file():
            issues.append(f"README target missing: {target}")
    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
            continue
        source = path.read_text(encoding="utf-8")
        if "eibfs_bottom_up_graph_cut_merging" not in source:
            issues.append(f"exported symbol text missing: {path.relative_to(ROOT)}")
        if "eibfs_maxflow" not in source:
            issues.append(f"EIBFS local solver reference missing: {path.relative_to(ROOT)}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"null guard missing: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json", "verify_workload.py",
                 "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
