"""Static source and metadata inventory helper; intentionally not executed."""

from __future__ import annotations

from pathlib import Path

from .verify_workload import verify

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "zeckendorf_addition"
PORTS = {
    "c": "c/z/zeckendorf_addition.c",
    "cpp": "cpp/z/zeckendorf_addition.cpp",
    "rust": "rust/z/zeckendorf_addition.rs",
    "elisa": "elisa/z/zeckendorf_addition.elisa",
    "c3": "c3/z/zeckendorf_addition.c3",
    "nim": "nim/z/zeckendorf_addition.nim",
    "odin": "odin/z/zeckendorf_addition.odin",
    "v": "v/z/zeckendorf_addition.v",
    "zig": "zig/z/zeckendorf_addition.zig",
    "mojo": "mojo/z/zeckendorf_addition.mojo",
}
NULL_GUARDS = {
    "c": "input == NULL",
    "cpp": "input == nullptr",
    "rust": "input.is_null()",
    "elisa": "input.is_null()",
    "c3": "input == null",
    "nim": "input.isNil",
    "odin": "input == nil",
    "v": "input == nil",
    "zig": "input == null",
    "mojo": "input.is_null()",
}
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json",
    "workload.json", "primary_oracle.py", "independent_oracle.py",
    "verify_workload.py", "check_inventory.py", "__init__.py",
)


def static_issues() -> list[str]:
    issues = verify()
    for name in REQUIRED:
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
        if SYMBOL not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"input null guard missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README link missing for {language}")
    elisa_path = ROOT / PORTS["elisa"]
    if elisa_path.is_file():
        elisa = elisa_path.read_text(encoding="utf-8")
        internal = elisa.split("def za_normalize", 1)[-1].split("@export", 1)[0]
        if "UnsafePointer" in internal or "*i64" in internal:
            issues.append("Elisa normalization internals should use bounded views")
    for source_url in (
        "https://www.fq.math.ca/Papers1/51-3/AhlbachUsatineFrougnyPippenger.pdf",
        "https://doi.org/10.1080/00150517.2013.12427944",
        "https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks",
    ):
        if source_url not in readme or source_url not in rights:
            issues.append(f"provenance URL missing from README or RIGHTS: {source_url}")
    return issues
