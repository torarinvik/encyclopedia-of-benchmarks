"""Static package inventory check; it does not compile or execute ports."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
ALGORITHM = "minimum_window_subsequence"
LANGUAGE_FILES = {
    "c": ROOT / "c/m/minimum_window_subsequence.c",
    "c3": ROOT / "c3/m/minimum_window_subsequence.c3",
    "cpp": ROOT / "cpp/m/minimum_window_subsequence.cpp",
    "elisa": ROOT / "elisa/m/minimum_window_subsequence.elisa",
    "mojo": ROOT / "mojo/m/minimum_window_subsequence.mojo",
    "nim": ROOT / "nim/m/minimum_window_subsequence.nim",
    "odin": ROOT / "odin/m/minimum_window_subsequence.odin",
    "rust": ROOT / "rust/m/minimum_window_subsequence.rs",
    "v": ROOT / "v/m/minimum_window_subsequence.v",
    "zig": ROOT / "zig/m/minimum_window_subsequence.zig",
}


def missing_files():
    return [str(path.relative_to(ROOT)) for path in LANGUAGE_FILES.values() if not path.is_file()]


def static_issues():
    issues = [f"missing language port: {path.relative_to(ROOT)}"
              for path in LANGUAGE_FILES.values() if not path.is_file()]
    package = Path(__file__).resolve().parent
    for required in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py", "independent_oracle.py"):
        if not (package / required).is_file():
            issues.append(f"missing package file: {required}")
    for language, path in LANGUAGE_FILES.items():
        if path.is_file() and ALGORITHM not in path.read_text(encoding="utf-8"):
            issues.append(f"{language} source does not mention the benchmark symbol")
    return issues


def main():
    issues = static_issues()
    if issues:
        raise SystemExit("; ".join(issues))
    print(f"{ALGORITHM}: {len(LANGUAGE_FILES)} language sources present")


if __name__ == "__main__":
    main()
