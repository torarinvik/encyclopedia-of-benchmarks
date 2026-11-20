"""Read-only structural inventory for the bounded k-truss package."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/k/k_truss_edge_peeling_decomposition"
SYMBOL = "k_truss_edge_peeling_decomposition"
SOURCES = {
    "c": ROOT / "c/k/k_truss_edge_peeling_decomposition.c",
    "c3": ROOT / "c3/k/k_truss_edge_peeling_decomposition.c3",
    "cpp": ROOT / "cpp/k/k_truss_edge_peeling_decomposition.cpp",
    "elisa": ROOT / "elisa/k/k_truss_edge_peeling_decomposition.elisa",
    "mojo": ROOT / "mojo/k/k_truss_edge_peeling_decomposition.mojo",
    "nim": ROOT / "nim/k/k_truss_edge_peeling_decomposition.nim",
    "odin": ROOT / "odin/k/k_truss_edge_peeling_decomposition.odin",
    "rust": ROOT / "rust/k/k_truss_edge_peeling_decomposition.rs",
    "v": ROOT / "v/k/k_truss_edge_peeling_decomposition.v",
    "zig": ROOT / "zig/k/k_truss_edge_peeling_decomposition.zig",
}


def check() -> None:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("input", {}).get("maximum_valid_length") != 242
            or workload.get("input", {}).get("maximum_parseable_length") != 243
            or workload.get("output", {}).get("maximum_bytes") != 960
            or workload.get("workspace", {}).get("bytes") != 16384):
        raise ValueError("k-truss workload differs from the reviewed bounded contract")
    identifiers = [case.get("id") for case in workload.get("cases", [])]
    if len(identifiers) != len(set(identifiers)) or "clique-four" not in identifiers:
        raise ValueError("k-truss fixtures are missing or duplicated")
    for relative in ("README.md", "RIGHTS.md", "INVENTORY.md",
                     "independent_threshold_reference.py", "static_inventory.py"):
        if not (PACKAGE / relative).is_file():
            raise ValueError(f"k-truss package artifact is missing: {relative}")
    primary = ROOT / "benchmarks/k_truss_edge_peeling_decomposition_oracle.py"
    if not primary.is_file() or "def expected_output" not in primary.read_text(encoding="utf-8"):
        raise ValueError("k-truss primary reference is missing")
    for language, source in SOURCES.items():
        if not source.is_file() or SYMBOL not in source.read_text(encoding="utf-8"):
            raise ValueError(f"k-truss {language} port is missing its export")
