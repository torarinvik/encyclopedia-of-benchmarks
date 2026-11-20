"""Check required files, port paths, exported symbols, and source notes without execution."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
ALGORITHM = "next_higher_number_with_same_number_of_set_bits"
PORTS = {
    "c": "c/n/next_higher_number_with_same_number_of_set_bits.c",
    "c3": "c3/n/next_higher_number_with_same_number_of_set_bits.c3",
    "cpp": "cpp/n/next_higher_number_with_same_number_of_set_bits.cpp",
    "elisa": "elisa/n/next_higher_number_with_same_number_of_set_bits.elisa",
    "mojo": "mojo/n/next_higher_number_with_same_number_of_set_bits.mojo",
    "nim": "nim/n/next_higher_number_with_same_number_of_set_bits.nim",
    "odin": "odin/n/next_higher_number_with_same_number_of_set_bits.odin",
    "rust": "rust/n/next_higher_number_with_same_number_of_set_bits.rs",
    "v": "v/n/next_higher_number_with_same_number_of_set_bits.v",
    "zig": "zig/n/next_higher_number_with_same_number_of_set_bits.zig",
}
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
)
SOURCES = (
    "https://dspace.mit.edu/bitstream/handle/1721.1/6086/AIM-239.pdf",
    "https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/bit_manipulation/next_higher_number_with_same_number_of_set_bits.cpp",
    "https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/NextHigherSameBitCount.java",
    "https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks",
)


def static_issues() -> list[str]:
    issues: list[str] = []
    for name in REQUIRED:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    except OSError as error:
        return issues + [f"cannot read package notes: {error}"]
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} source: {relative}")
            continue
        if ALGORITHM not in path.read_text(encoding="utf-8"):
            issues.append(f"export symbol absent from {relative}")
        if relative not in readme:
            issues.append(f"README source link missing for {language}")
    for source in SOURCES:
        if source not in readme or source not in rights:
            issues.append(f"source URL missing from README or RIGHTS: {source}")
    for filename in ("primary_oracle.py", "independent_oracle.py"):
        if "def expected_result" not in (PACKAGE / filename).read_text(encoding="utf-8"):
            issues.append(f"reference function missing from {filename}")
    return issues
