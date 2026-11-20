"""Static source/provenance inventory; does not execute benchmark code."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SYMBOL = "aliquot_orbit_decomposition"
PORTS = {
    "c": "c/a/aliquot_orbit_decomposition.c",
    "c3": "c3/a/aliquot_orbit_decomposition.c3",
    "cpp": "cpp/a/aliquot_orbit_decomposition.cpp",
    "elisa": "elisa/a/aliquot_orbit_decomposition.elisa",
    "mojo": "mojo/a/aliquot_orbit_decomposition.mojo",
    "nim": "nim/a/aliquot_orbit_decomposition.nim",
    "odin": "odin/a/aliquot_orbit_decomposition.odin",
    "rust": "rust/a/aliquot_orbit_decomposition.rs",
    "v": "v/a/aliquot_orbit_decomposition.v",
    "zig": "zig/a/aliquot_orbit_decomposition.zig",
}
SOURCES = (
    "https://oeis.org/wiki/Aliquot_sequences",
    "https://mathworld.wolfram.com/AliquotSequence.html",
    "https://mathworld.wolfram.com/DivisorFunction.html",
    "https://oeis.org/A044050",
    "https://rosettagit.org/tasks/",
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
            issues.append(f"INVENTORY link missing for {language}: {relative}")
    for url in SOURCES:
        if url not in readme or url not in rights:
            issues.append(f"source URL missing from README or RIGHTS: {url}")
    for name in ("primary_oracle.py", "independent_oracle.py"):
        source = (PACKAGE / name).read_text(encoding="utf-8")
        if "expected_output" not in source:
            issues.append(f"expected-output reference missing from {name}")
    if workload.get("algorithm") != SYMBOL or workload.get("abi") != "i64_array_bytes_output":
        issues.append("workload algorithm or ABI metadata mismatch")
    if len(workload.get("cases", [])) < 10:
        issues.append("workload has fewer than ten static cases")
    return issues
