"""Static package and provenance inventory; language ports are not executed."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/b/baum_welch_reestimation.c",
    "c3": "c3/b/baum_welch_reestimation.c3",
    "cpp": "cpp/b/baum_welch_reestimation.cpp",
    "elisa": "elisa/b/baum_welch_reestimation.elisa",
    "mojo": "mojo/b/baum_welch_reestimation.mojo",
    "nim": "nim/b/baum_welch_reestimation.nim",
    "odin": "odin/b/baum_welch_reestimation.odin",
    "rust": "rust/b/baum_welch_reestimation.rs",
    "v": "v/b/baum_welch_reestimation.v",
    "zig": "zig/b/baum_welch_reestimation.zig",
}
INPUT_GUARDS = {
    "c": "input == NULL", "c3": "input == null", "cpp": "input == nullptr",
    "elisa": "input.is_null()", "mojo": "UnsafePointer[Float64, ImmutAnyOrigin]()",
    "nim": "input.isNil", "odin": "input == nil", "rust": "input.is_null()",
    "v": "input == nil", "zig": "input orelse return -1",
}
OUTPUT_GUARDS = {
    "c": "output == NULL", "c3": "output == null", "cpp": "output == nullptr",
    "elisa": "output.is_null()", "mojo": "UnsafePointer[Float64, MutAnyOrigin]()",
    "nim": "output.isNil", "odin": "output == nil", "rust": "output.is_null()",
    "v": "output == nil", "zig": "output orelse return -2",
}
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    "check_inventory.py",
)
PROVENANCE_URLS = (
    "https://doi.org/10.1109/5.18626",
    "https://xlinux.nist.gov/dads/HTML/baumWelch.html",
    "https://xlinux.nist.gov/dads/ui.html",
)


def static_issues() -> list[str]:
    issues: list[str] = []
    for filename in REQUIRED:
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package artifact: {filename}")
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
        if "baum_welch_reestimation" not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if INPUT_GUARDS[language] not in source:
            issues.append(f"null-input guard missing from {relative}")
        if OUTPUT_GUARDS[language] not in source:
            issues.append(f"null-output guard missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README source link mismatch for {language}")
    for url in PROVENANCE_URLS:
        if url not in readme or url not in rights:
            issues.append(f"provenance URL missing from README or RIGHTS: {url}")
    for filename in ("primary_oracle.py", "independent_oracle.py"):
        if "def expected_output" not in (PACKAGE / filename).read_text(encoding="utf-8"):
            issues.append(f"expected-output reference missing from {filename}")
    elisa = (ROOT / PORTS["elisa"]).read_text(encoding="utf-8")
    if "UnsafePointer" in elisa or "*f64" in elisa:
        issues.append("Elisa computation should use bounded views internally")
    return issues
