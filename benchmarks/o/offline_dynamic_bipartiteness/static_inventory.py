"""Read-only structural inventory for the offline bipartiteness package."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks" / "o" / "offline_dynamic_bipartiteness"
SYMBOL = "offline_dynamic_bipartiteness"
SOURCES = {
    "c": ROOT / "c/o/offline_dynamic_bipartiteness.c",
    "c3": ROOT / "c3/o/offline_dynamic_bipartiteness.c3",
    "cpp": ROOT / "cpp/o/offline_dynamic_bipartiteness.cpp",
    "elisa": ROOT / "elisa/o/offline_dynamic_bipartiteness.elisa",
    "mojo": ROOT / "mojo/o/offline_dynamic_bipartiteness.mojo",
    "nim": ROOT / "nim/o/offline_dynamic_bipartiteness.nim",
    "odin": ROOT / "odin/o/offline_dynamic_bipartiteness.odin",
    "rust": ROOT / "rust/o/offline_dynamic_bipartiteness.rs",
    "v": ROOT / "v/o/offline_dynamic_bipartiteness.v",
    "zig": ROOT / "zig/o/offline_dynamic_bipartiteness.zig",
}


def check() -> None:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("input", {}).get("maximum_valid_length") != 258
            or workload.get("input", {}).get("maximum_parseable_length") != 259
            or workload.get("output", {}).get("maximum_bytes") != 512
            or workload.get("workspace", {}).get("bytes") != 196608):
        raise ValueError("offline_dynamic_bipartiteness metadata differs from its reviewed contract")
    ids = [case.get("id") for case in workload.get("cases", [])]
    if len(ids) != len(set(ids)) or "maximum-input-and-output" not in ids:
        raise ValueError("offline_dynamic_bipartiteness fixtures are missing or duplicated")
    for relative in (
        "README.md", "RIGHTS.md", "INVENTORY.md", "independent_bfs_reference.py",
        "static_inventory.py",
    ):
        if not (PACKAGE / relative).is_file():
            raise ValueError(f"offline_dynamic_bipartiteness package artifact is missing: {relative}")
    primary = ROOT / "benchmarks/offline_dynamic_bipartiteness_oracle.py"
    if not primary.is_file() or "def expected_output" not in primary.read_text(encoding="utf-8"):
        raise ValueError("offline_dynamic_bipartiteness primary reference is missing")
    for language, source in SOURCES.items():
        if not source.is_file() or SYMBOL not in source.read_text(encoding="utf-8"):
            raise ValueError(f"offline_dynamic_bipartiteness {language} port is missing its export")

