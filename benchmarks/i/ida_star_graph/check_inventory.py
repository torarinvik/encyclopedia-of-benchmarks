"""Static source inventory for the bounded IDA* benchmark; not run on creation."""

from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = {
    "c": "c/i/ida_star_graph.c",
    "c3": "c3/i/ida_star_graph.c3",
    "cpp": "cpp/i/ida_star_graph.cpp",
    "elisa": "elisa/i/ida_star_graph.elisa",
    "mojo": "mojo/i/ida_star_graph.mojo",
    "nim": "nim/i/ida_star_graph.nim",
    "odin": "odin/i/ida_star_graph.odin",
    "rust": "rust/i/ida_star_graph.rs",
    "v": "v/i/ida_star_graph.v",
    "zig": "zig/i/ida_star_graph.zig",
}


def static_issues() -> list[str]:
    issues = []
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing {name}")
    if not (ROOT / "benchmarks/i/ida_star_graph_oracle.py").is_file():
        issues.append("missing BFS reference")
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} port: {relative}")
        elif "ida_star_graph" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing symbol marker in {relative}")
    return issues
