"""Static source/provenance inventory; does not execute benchmark code."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SYMBOL = "longest_common_increasing_subsequence"
PORTS = {
    "c": "c/l/longest_common_increasing_subsequence.c",
    "c3": "c3/l/longest_common_increasing_subsequence.c3",
    "cpp": "cpp/l/longest_common_increasing_subsequence.cpp",
    "elisa": "elisa/l/longest_common_increasing_subsequence.elisa",
    "mojo": "mojo/l/longest_common_increasing_subsequence.mojo",
    "nim": "nim/l/longest_common_increasing_subsequence.nim",
    "odin": "odin/l/longest_common_increasing_subsequence.odin",
    "rust": "rust/l/longest_common_increasing_subsequence.rs",
    "v": "v/l/longest_common_increasing_subsequence.v",
    "zig": "zig/l/longest_common_increasing_subsequence.zig",
}
SOURCES = (
    "https://doi.org/10.1016/j.ipl.2004.10.014",
    "https://doi.org/10.4230/LIPIcs.STACS.2020.41",
    "https://arxiv.org/abs/1608.07002",
    "https://github.com/sgtlaugh/algovault",
)


def static_issues() -> list[str]:
    issues: list[str] = []
    required = (
        "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
        "primary_oracle.py", "independent_oracle.py", "check_inventory.py",
    )
    for name in required:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
        inventory = (PACKAGE / "INVENTORY.md").read_text(encoding="utf-8")
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read static package metadata: {error}"]
    for language, relative in PORTS.items():
        port = ROOT / relative
        if not port.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        source = port.read_text(encoding="utf-8")
        if SYMBOL not in source:
            issues.append(f"export symbol missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README link missing for {language}")
        if relative not in inventory:
            issues.append(f"inventory entry missing for {language}")
    for url in SOURCES:
        if url not in readme or url not in rights:
            issues.append(f"source URL missing from README or RIGHTS: {url}")
    for name in ("primary_oracle.py", "independent_oracle.py"):
        if "expected_result" not in (PACKAGE / name).read_text(encoding="utf-8"):
            issues.append(f"expected-result reference missing from {name}")
    if workload.get("algorithm") != SYMBOL or workload.get("abi") != "i64_array_scalar":
        issues.append("workload algorithm or ABI metadata mismatch")
    if len(workload.get("cases", [])) < 10:
        issues.append("workload has fewer than ten static cases")
    return issues
