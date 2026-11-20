"""Check source/package inventory only; never builds or executes a port."""

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
NAME = "pisinger_bounded_weight_subset_sum"
PORTS = {
    "c": f"c/p/{NAME}.c",
    "c3": f"c3/p/{NAME}.c3",
    "cpp": f"cpp/p/{NAME}.cpp",
    "elisa": f"elisa/p/{NAME}.elisa",
    "mojo": f"mojo/p/{NAME}.mojo",
    "nim": f"nim/p/{NAME}.nim",
    "odin": f"odin/p/{NAME}.odin",
    "rust": f"rust/p/{NAME}.rs",
    "v": f"v/p/{NAME}.v",
    "zig": f"zig/p/{NAME}.zig",
}
PACKAGE = ROOT / "benchmarks/p" / NAME


def check_inventory() -> None:
    for relative in PORTS.values():
        source = ROOT / relative
        if not source.is_file() or NAME not in source.read_text(encoding="utf-8"):
            raise ValueError(f"missing port or exported symbol: {relative}")
    for filename in (
        "README.md",
        "RIGHTS.md",
        "INVENTORY.md",
        "workload.json",
        "primary_oracle.py",
        "independent_oracle.py",
        "verify_workload.py",
    ):
        if not (PACKAGE / filename).is_file():
            raise ValueError(f"missing package artifact: {filename}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    if "10.1006/jagm.1999.1034" not in readme or "FastKnapsack.h" not in readme:
        raise ValueError("source/provenance documentation is incomplete")


if __name__ == "__main__":
    check_inventory()
