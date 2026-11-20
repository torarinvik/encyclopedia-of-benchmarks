"""Static inventory metadata for edge_colored_graph_layer_encoding."""
from __future__ import annotations

from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
FILES = (
    "benchmarks/e/edge_colored_graph_layer_encoding/README.md",
    "benchmarks/e/edge_colored_graph_layer_encoding/INVENTORY.md",
    "benchmarks/e/edge_colored_graph_layer_encoding/RIGHTS.md",
    "benchmarks/e/edge_colored_graph_layer_encoding/workload.json",
    "benchmarks/e/edge_colored_graph_layer_encoding/primary_oracle.py",
    "benchmarks/e/edge_colored_graph_layer_encoding/independent_oracle.py",
    "benchmarks/e/edge_colored_graph_layer_encoding/verify_workload.py",
    "c/e/edge_colored_graph_layer_encoding.c",
    "c3/e/edge_colored_graph_layer_encoding.c3",
    "cpp/e/edge_colored_graph_layer_encoding.cpp",
    "elisa/e/edge_colored_graph_layer_encoding.elisa",
    "mojo/e/edge_colored_graph_layer_encoding.mojo",
    "nim/e/edge_colored_graph_layer_encoding.nim",
    "odin/e/edge_colored_graph_layer_encoding.odin",
    "rust/e/edge_colored_graph_layer_encoding.rs",
    "v/e/edge_colored_graph_layer_encoding.v",
    "zig/e/edge_colored_graph_layer_encoding.zig",
)


def static_issues() -> list[str]:
    return [name for name in FILES if not (ROOT / name).is_file()]


if __name__ == "__main__":
    for missing in static_issues():
        print(f"missing: {missing}")
    raise SystemExit(bool(static_issues()))
