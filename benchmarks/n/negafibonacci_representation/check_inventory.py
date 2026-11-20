"""Static artifact-presence check for the NegaFibonacci package."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
STEM = "negafibonacci_representation"
SOURCES = {
    "C": ROOT / "c/n/negafibonacci_representation.c",
    "C3": ROOT / "c3/n/negafibonacci_representation.c3",
    "C++": ROOT / "cpp/n/negafibonacci_representation.cpp",
    "Elisa": ROOT / "elisa/n/negafibonacci_representation.elisa",
    "Mojo": ROOT / "mojo/n/negafibonacci_representation.mojo",
    "Nim": ROOT / "nim/n/negafibonacci_representation.nim",
    "Odin": ROOT / "odin/n/negafibonacci_representation.odin",
    "Rust": ROOT / "rust/n/negafibonacci_representation.rs",
    "V": ROOT / "v/n/negafibonacci_representation.v",
    "Zig": ROOT / "zig/n/negafibonacci_representation.zig",
}
REQUIRED = [
    PACKAGE / "README.md", PACKAGE / "RIGHTS.md", PACKAGE / "INVENTORY.md",
    PACKAGE / "workload.json", PACKAGE / "primary_oracle.py",
    PACKAGE / "independent_oracle.py",
]


def missing_artifacts() -> list[str]:
    missing = [str(path.relative_to(ROOT)) for path in REQUIRED if not path.is_file()]
    missing.extend(str(path.relative_to(ROOT)) for path in SOURCES.values() if not path.is_file())
    return missing


if __name__ == "__main__":
    missing = missing_artifacts()
    if missing:
        raise SystemExit("missing static package artifacts: " + ", ".join(missing))
    print(f"{STEM}: ten source ports and package artifacts are present")
