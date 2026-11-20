"""Static package inventory; source files are inspected but never executed."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SOURCES = tuple(
    ROOT / path for path in (
        "c/w/wulff_nilsen_distance_refinement.c",
        "c3/w/wulff_nilsen_distance_refinement.c3",
        "cpp/w/wulff_nilsen_distance_refinement.cpp",
        "elisa/w/wulff_nilsen_distance_refinement.elisa",
        "mojo/w/wulff_nilsen_distance_refinement.mojo",
        "nim/w/wulff_nilsen_distance_refinement.nim",
        "odin/w/wulff_nilsen_distance_refinement.odin",
        "rust/w/wulff_nilsen_distance_refinement.rs",
        "v/wulff_nilsen_distance_refinement.v",
        "zig/w/wulff_nilsen_distance_refinement.zig",
    )
)
REQUIRED = (
    PACKAGE / "README.md", PACKAGE / "RIGHTS.md", PACKAGE / "INVENTORY.md",
    PACKAGE / "inventory.json", PACKAGE / "workload.json", PACKAGE / "check_inventory.py",
    PACKAGE / "verify_workload.py",
    ROOT / "benchmarks/wulff_nilsen_distance_refinement_oracle.py",
    ROOT / "benchmarks/wulff_nilsen_distance_refinement_independent_oracle.py",
)


def static_issues():
    issues = [str(path.relative_to(ROOT)) for path in (*REQUIRED, *SOURCES) if not path.is_file()]
    for path in SOURCES:
        if path.is_file() and "wulff_nilsen_distance_refinement" not in path.read_text(encoding="utf-8"):
            issues.append(str(path.relative_to(ROOT)) + ": exported symbol text missing")
    return issues


def check_inventory():
    return static_issues()


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
    print("static inventory complete")
