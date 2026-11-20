"""Static package inventory check; this module does not compile or execute ports."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
LANGUAGES = ("c", "c3", "cpp", "elisa", "mojo", "nim", "odin", "rust", "v", "zig")
EXTENSIONS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa", "mojo": "mojo",
    "nim": "nim", "odin": "odin", "rust": "rs", "v": "v", "zig": "zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    for language in LANGUAGES:
        path = ROOT / language / "f" / f"four_square_sum_representation.{EXTENSIONS[language]}"
        if not path.is_file():
            issues.append(f"missing {language} port")
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "verify_workload.py"):
        if not (ROOT / "benchmarks" / "f" / "four_square_sum_representation" / name).is_file():
            issues.append(f"missing package file {name}")
    return issues
