"""Static file/export/provenance inventory; does not execute benchmark code."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/h/havel_hakimi_graph_realization.c",
    "c3": "c3/h/havel_hakimi_graph_realization.c3",
    "cpp": "cpp/h/havel_hakimi_graph_realization.cpp",
    "elisa": "elisa/h/havel_hakimi_graph_realization.elisa",
    "mojo": "mojo/h/havel_hakimi_graph_realization.mojo",
    "nim": "nim/h/havel_hakimi_graph_realization.nim",
    "odin": "odin/h/havel_hakimi_graph_realization.odin",
    "rust": "rust/h/havel_hakimi_graph_realization.rs",
    "v": "v/h/havel_hakimi_graph_realization.v",
    "zig": "zig/h/havel_hakimi_graph_realization.zig",
}
SOURCES = (
    "https://networkx.org/documentation/stable/reference/generated/networkx.generators.degree_seq.havel_hakimi_graph.html",
    "https://doi.org/10.1137/0110037",
    "https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.graphical.is_valid_degree_sequence_erdos_gallai.html",
)


def static_issues() -> list[str]:
    issues: list[str] = []
    for name in (
        "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
        "primary_oracle.py", "independent_oracle.py", "check_inventory.py",
    ):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    except OSError as error:
        return issues + [f"cannot read package documentation: {error}"]
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if "havel_hakimi_graph_realization" not in source:
            issues.append(f"export symbol missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README link missing for {language}")
    for url in SOURCES:
        if url not in readme or url not in rights:
            issues.append(f"source URL missing from README or RIGHTS: {url}")
    for oracle in ("primary_oracle.py", "independent_oracle.py"):
        source = (PACKAGE / oracle).read_text(encoding="utf-8")
        if "expected_output" not in source:
            issues.append(f"expected-output reference missing from {oracle}")
    return issues
