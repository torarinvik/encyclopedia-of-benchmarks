"""Static package and port inventory for the 3D Bird–Baker profile."""
from __future__ import annotations

from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
FILES = (
    "benchmarks/t/three_dimensional_bird_baker_matching/README.md",
    "benchmarks/t/three_dimensional_bird_baker_matching/INVENTORY.md",
    "benchmarks/t/three_dimensional_bird_baker_matching/RIGHTS.md",
    "benchmarks/t/three_dimensional_bird_baker_matching/workload.json",
    "benchmarks/t/three_dimensional_bird_baker_matching/primary_oracle.py",
    "benchmarks/t/three_dimensional_bird_baker_matching/independent_oracle.py",
    "benchmarks/t/three_dimensional_bird_baker_matching/verify_workload.py",
    "c/t/three_dimensional_bird_baker_matching.c",
    "c3/t/three_dimensional_bird_baker_matching.c3",
    "cpp/t/three_dimensional_bird_baker_matching.cpp",
    "elisa/t/three_dimensional_bird_baker_matching.elisa",
    "mojo/t/three_dimensional_bird_baker_matching.mojo",
    "nim/t/three_dimensional_bird_baker_matching.nim",
    "odin/t/three_dimensional_bird_baker_matching.odin",
    "rust/t/three_dimensional_bird_baker_matching.rs",
    "v/t/three_dimensional_bird_baker_matching.v",
    "zig/t/three_dimensional_bird_baker_matching.zig",
)


def static_issues() -> list[str]:
    return [name for name in FILES if not (ROOT / name).is_file()]


if __name__ == "__main__":
    for missing in static_issues():
        print(f"missing: {missing}")
    raise SystemExit(bool(static_issues()))
