"""Static source-presence inventory for the nonogram package; not a runner."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
STEM = "nonogram_line_domain_solver"
SOURCES = {
    "C": ROOT / "c/n/nonogram_line_domain_solver.c",
    "C3": ROOT / "c3/n/nonogram_line_domain_solver.c3",
    "C++": ROOT / "cpp/n/nonogram_line_domain_solver.cpp",
    "Elisa": ROOT / "elisa/n/nonogram_line_domain_solver.elisa",
    "Mojo": ROOT / "mojo/n/nonogram_line_domain_solver.mojo",
    "Nim": ROOT / "nim/n/nonogram_line_domain_solver.nim",
    "Odin": ROOT / "odin/n/nonogram_line_domain_solver.odin",
    "Rust": ROOT / "rust/n/nonogram_line_domain_solver.rs",
    "V": ROOT / "v/n/nonogram_line_domain_solver.v",
    "Zig": ROOT / "zig/n/nonogram_line_domain_solver.zig",
}
REQUIRED = [
    PACKAGE / "README.md", PACKAGE / "RIGHTS.md", PACKAGE / "INVENTORY.md",
    PACKAGE / "workload.json", PACKAGE / "primary_oracle.py",
    PACKAGE / "independent_oracle.py", PACKAGE / "check_inventory.py",
]


def missing_artifacts() -> list[str]:
    missing = [str(path.relative_to(ROOT)) for path in REQUIRED if not path.is_file()]
    for language, path in SOURCES.items():
        if not path.is_file():
            missing.append(str(path.relative_to(ROOT)))
        elif STEM not in path.read_text(encoding="utf-8"):
            missing.append(f"{path.relative_to(ROOT)} (missing exported symbol; {language})")
    return missing


if __name__ == "__main__":
    missing = missing_artifacts()
    if missing:
        raise SystemExit("missing static package artifacts: " + ", ".join(missing))
    print(f"{STEM}: all ten source files and package artifacts are present")
