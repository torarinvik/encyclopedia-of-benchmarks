"""Static artifact/source-presence check; intentionally does not execute ports."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SOURCES = (
    ROOT / "c/h/hanging_line_largest_rectangle.c",
    ROOT / "c3/h/hanging_line_largest_rectangle.c3",
    ROOT / "cpp/h/hanging_line_largest_rectangle.cpp",
    ROOT / "elisa/h/hanging_line_largest_rectangle.elisa",
    ROOT / "mojo/h/hanging_line_largest_rectangle.mojo",
    ROOT / "nim/h/hanging_line_largest_rectangle.nim",
    ROOT / "odin/h/hanging_line_largest_rectangle.odin",
    ROOT / "rust/h/hanging_line_largest_rectangle.rs",
    ROOT / "v/h/hanging_line_largest_rectangle.v",
    ROOT / "zig/h/hanging_line_largest_rectangle.zig",
)
REQUIRED = (
    PACKAGE / "README.md",
    PACKAGE / "RIGHTS.md",
    PACKAGE / "INVENTORY.md",
    PACKAGE / "workload.json",
    PACKAGE / "primary_oracle.py",
    PACKAGE / "independent_oracle.py",
    PACKAGE / "validation.py",
    PACKAGE / "verify_workload.py",
    PACKAGE / "check_inventory.py",
)


def missing_artifacts():
    missing = [str(path.relative_to(ROOT)) for path in (*REQUIRED, *SOURCES) if not path.is_file()]
    if missing:
        return missing
    for path in SOURCES:
        source = path.read_text(encoding="utf-8")
        if "hanging_line_largest_rectangle" not in source:
            missing.append(str(path.relative_to(ROOT)) + ": exported symbol not found")
        if "stack" in source.lower():
            missing.append(str(path.relative_to(ROOT)) + ": stack-based source term found")
    return missing


if __name__ == "__main__":
    missing = missing_artifacts()
    if missing:
        raise SystemExit("missing or inconsistent package artifacts: " + ", ".join(missing))
    print("hanging_line_largest_rectangle: ten link-reuse ports and package artifacts are present")
