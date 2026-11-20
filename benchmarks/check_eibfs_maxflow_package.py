"""Static inventory, contract, and provenance check for EIBFS."""

from __future__ import annotations

import json
from pathlib import Path

from e.eibfs_maxflow.verify_workload import verify as verify_workload

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/e/eibfs_maxflow"
PORTS = {
    "c": ROOT / "c/e/eibfs_maxflow.c",
    "c3": ROOT / "c3/e/eibfs_maxflow.c3",
    "cpp": ROOT / "cpp/e/eibfs_maxflow.cpp",
    "elisa": ROOT / "elisa/e/eibfs_maxflow.elisa",
    "mojo": ROOT / "mojo/e/eibfs_maxflow.mojo",
    "nim": ROOT / "nim/e/eibfs_maxflow.nim",
    "odin": ROOT / "odin/e/eibfs_maxflow.odin",
    "rust": ROOT / "rust/e/eibfs_maxflow.rs",
    "v": ROOT / "v/e/eibfs_maxflow.v",
    "zig": ROOT / "zig/e/eibfs_maxflow.zig",
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
PAPER = "https://www.microsoft.com/en-us/research/wp-content/uploads/2016/11/ghkktw_ESA2015.pdf"


def static_issues() -> list[str]:
    issues = verify_workload()
    try:
        data = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read workload: {error}"]
    if data.get("pinned_source", {}).get("paper_pdf") != PAPER:
        issues.append("paper URL mismatch")
    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
            continue
        source = path.read_text(encoding="utf-8")
        if "eibfs_maxflow" not in source:
            issues.append(f"exported symbol text missing: {path.relative_to(ROOT)}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"null guard missing: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")
    for name in ("eibfs_maxflow_oracle.py", "eibfs_maxflow_verifier_oracle.py"):
        if not (ROOT / "benchmarks" / name).is_file():
            issues.append(f"missing oracle: {name}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8") if (PACKAGE / "README.md").is_file() else ""
    if PAPER not in readme or "independent reference enumerates" not in readme:
        issues.append("README missing paper provenance or independent-method note")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
