"""Static artifact and source-presence check; never compiles or runs ports."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
STEM = "android_unlock_pattern_count"
PORTS = {
    "C": "c/a/android_unlock_pattern_count.c",
    "C3": "c3/a/android_unlock_pattern_count.c3",
    "C++": "cpp/a/android_unlock_pattern_count.cpp",
    "Elisa": "elisa/a/android_unlock_pattern_count.elisa",
    "Mojo": "mojo/a/android_unlock_pattern_count.mojo",
    "Nim": "nim/a/android_unlock_pattern_count.nim",
    "Odin": "odin/a/android_unlock_pattern_count.odin",
    "Rust": "rust/a/android_unlock_pattern_count.rs",
    "V": "v/a/android_unlock_pattern_count.v",
    "Zig": "zig/a/android_unlock_pattern_count.zig",
}
NULL_GUARDS = {
    "C": "input == NULL",
    "C3": "input == null",
    "C++": "input == nullptr",
    "Elisa": "input.is_null()",
    "Mojo": "UnsafePointer[Int64, ImmutAnyOrigin]()",
    "Nim": "input.isNil",
    "Odin": "input == nil",
    "Rust": "input.is_null()",
    "V": "input == nil",
    "Zig": "input == null",
}
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "check_inventory.py",
)
METHOD_URLS = (
    "https://doi.org/10.1145/2508859.2516700",
    "https://doi.org/10.1587/transinf.2016EDL8196",
    "https://oeis.org/A163889",
)


def static_issues() -> list[str]:
    issues = [f"missing package artifact: {name}" for name in REQUIRED
              if not (PACKAGE / name).is_file()]
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read package metadata: {error}"]

    if workload.get("algorithm") != STEM or workload.get("function_symbol") != STEM:
        issues.append("workload identity does not match the exported symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("workload ABI is not i64_array_scalar")
    for case in workload.get("cases", []):
        if "expected_result" not in case or "input_values" not in case:
            issues.append(f"fixture lacks scalar fields: {case.get('id', '<unnamed>')}")
    for url in METHOD_URLS:
        if url not in readme or url not in rights or url not in str(workload):
            issues.append(f"method/count source missing from package metadata: {url}")

    for language, relative in PORTS.items():
        source_path = ROOT / relative
        if not source_path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        try:
            source = source_path.read_text(encoding="utf-8")
        except OSError as error:
            issues.append(f"cannot read {relative}: {error}")
            continue
        if STEM not in source:
            issues.append(f"export symbol missing from {relative}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"null-input guard missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README source link mismatch for {relative}")

    elisa = (ROOT / PORTS["Elisa"]).read_text(encoding="utf-8")
    if "UnsafePointer" in elisa or "*i64" in elisa:
        issues.append("Elisa port should keep the C ABI input as a borrowed reference")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("static package inventory issues: " + "; ".join(problems))
    print("android_unlock_pattern_count: ten ports and package artifacts are present")
