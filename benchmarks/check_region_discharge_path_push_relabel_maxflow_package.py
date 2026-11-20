"""Static inventory checks for the bounded sequential S-ARD package."""

from __future__ import annotations

import json
import re
from pathlib import Path

from benchmarks.r.region_discharge_path_push_relabel_maxflow.verify_workload import verify as verify_workload

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/r/region_discharge_path_push_relabel_maxflow"
PORTS = {
    "c": ROOT / "c/r/region_discharge_path_push_relabel_maxflow.c",
    "c3": ROOT / "c3/r/region_discharge_path_push_relabel_maxflow.c3",
    "cpp": ROOT / "cpp/r/region_discharge_path_push_relabel_maxflow.cpp",
    "elisa": ROOT / "elisa/r/region_discharge_path_push_relabel_maxflow.elisa",
    "mojo": ROOT / "mojo/r/region_discharge_path_push_relabel_maxflow.mojo",
    "nim": ROOT / "nim/r/region_discharge_path_push_relabel_maxflow.nim",
    "odin": ROOT / "odin/r/region_discharge_path_push_relabel_maxflow.odin",
    "rust": ROOT / "rust/r/region_discharge_path_push_relabel_maxflow.rs",
    "v": ROOT / "v/r/region_discharge_path_push_relabel_maxflow.v",
    "zig": ROOT / "zig/r/region_discharge_path_push_relabel_maxflow.zig",
}
NULL_GUARDS = {
    "c": "input == NULL",
    "c3": "input == null",
    "cpp": "input == NULL",
    "elisa": "input.is_null()",
    "mojo": "UnsafePointer[Int64, ImmutAnyOrigin]()",
    "nim": "input.isNil",
    "odin": "input == nil",
    "rust": "input.is_null()",
    "v": "input == nil",
    "zig": "input == null",
}
SOURCES = (
    "https://cmp.felk.cvut.cz/~shekhovt/publications/shekhovtsov-11-mixed_maxflow.pdf",
    "https://cmp.felk.cvut.cz/~shekhovt/publications/shekhovtsov-11-mixed_maxflow-TR.pdf",
    "https://arxiv.org/abs/1109.1146",
)


def static_issues() -> list[str]:
    issues = verify_workload()
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read workload: {error}"]
    if workload.get("algorithm") != "region_discharge_path_push_relabel_maxflow":
        issues.append("algorithm ID mismatch")
    if workload.get("function_symbol") != "region_discharge_path_push_relabel_maxflow":
        issues.append("function symbol mismatch")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("ABI mismatch")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for source in SOURCES:
        if source not in readme:
            issues.append(f"README missing source: {source}")
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
        if "region_discharge_path_push_relabel_maxflow" not in source:
            issues.append(f"exported symbol text missing: {path.relative_to(ROOT)}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"null guard missing: {path.relative_to(ROOT)}")
        if "boundary_count" not in source and "boundaryCount" not in source:
            issues.append(f"ARD boundary-stage logic missing: {path.relative_to(ROOT)}")
        if "labels" not in source and "label" not in source:
            issues.append(f"region labels missing: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json", "verify_workload.py",
                 "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
