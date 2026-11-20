"""Static source, artifact, export, and provenance inventory."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/l/liu_hui_pi_approximation.c",
    "c3": "c3/l/liu_hui_pi_approximation.c3",
    "cpp": "cpp/l/liu_hui_pi_approximation.cpp",
    "elisa": "elisa/l/liu_hui_pi_approximation.elisa",
    "mojo": "mojo/l/liu_hui_pi_approximation.mojo",
    "nim": "nim/l/liu_hui_pi_approximation.nim",
    "odin": "odin/l/liu_hui_pi_approximation.odin",
    "rust": "rust/l/liu_hui_pi_approximation.rs",
    "v": "v/l/liu_hui_pi_approximation.v",
    "zig": "zig/l/liu_hui_pi_approximation.zig",
}
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    "check_inventory.py",
)
PROVENANCE = (
    "https://mathworld.wolfram.com/LiuHuisExhaustionMethod.html",
    "https://mathshistory.st-andrews.ac.uk/Biographies/Liu_Hui/",
    "https://github.com/trekhleb/javascript-algorithms#algorithms",
)


def static_issues() -> list[str]:
    issues: list[str] = []
    for name in REQUIRED:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")

    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    except OSError as error:
        return issues + [f"cannot read package documentation: {error}"]

    for language, relative in PORTS.items():
        source_path = ROOT / relative
        if not source_path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        source = source_path.read_text(encoding="utf-8")
        if "liu_hui_pi_approximation" not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README link mismatch for {language}")

    for url in PROVENANCE:
        if url not in readme or url not in rights:
            issues.append(f"provenance URL missing from README or RIGHTS: {url}")

    for reference in ("primary_oracle.py", "independent_oracle.py"):
        source = (PACKAGE / reference).read_text(encoding="utf-8")
        if "expected_output" not in source:
            issues.append(f"expected-output reference missing from {reference}")

    checker = (PACKAGE / "check_inventory.py").read_text(encoding="utf-8")
    if "subprocess" in checker:
        issues.append("inventory checker must remain a static source/documentation audit")
    return issues
