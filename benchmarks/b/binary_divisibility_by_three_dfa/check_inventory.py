"""Static package-presence check; never compiles or executes language ports."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
STEM = "binary_divisibility_by_three_dfa"
PORTS = {
    "C": "c/b/binary_divisibility_by_three_dfa.c",
    "C3": "c3/b/binary_divisibility_by_three_dfa.c3",
    "C++": "cpp/b/binary_divisibility_by_three_dfa.cpp",
    "Elisa": "elisa/b/binary_divisibility_by_three_dfa.elisa",
    "Mojo": "mojo/b/binary_divisibility_by_three_dfa.mojo",
    "Nim": "nim/b/binary_divisibility_by_three_dfa.nim",
    "Odin": "odin/b/binary_divisibility_by_three_dfa.odin",
    "Rust": "rust/b/binary_divisibility_by_three_dfa.rs",
    "V": "v/b/binary_divisibility_by_three_dfa.v",
    "Zig": "zig/b/binary_divisibility_by_three_dfa.zig",
}
NULL_INPUT_GUARDS = {
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
OUTPUT_NULL_GUARDS = {
    "C": "output == NULL",
    "C3": "output == null",
    "C++": "output == nullptr",
    "Elisa": "output.is_null()",
    "Mojo": "UnsafePointer[UInt8, MutAnyOrigin]()",
    "Nim": "output.isNil",
    "Odin": "output == nil",
    "Rust": "output.is_null()",
    "V": "output == nil",
    "Zig": "output == null",
}
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "RESERVATION.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py", "check_inventory.py",
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
    if (workload.get("algorithm") != STEM or workload.get("function_symbol") != STEM
            or workload.get("abi") != "i64_array_bytes_output"):
        issues.append("workload identity differs from the exported byte-output contract")
    if "Codewars public title" not in str(workload.get("source", {})):
        issues.append("workload omits title-only discovery scope")
    if "No problem statement" not in rights or "clean-room" not in rights:
        issues.append("rights note omits the discovery-only and clean-room boundaries")

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
        if NULL_INPUT_GUARDS[language] not in source:
            issues.append(f"null-input guard missing from {relative}")
        if OUTPUT_NULL_GUARDS[language] not in source:
            issues.append(f"null-output guard missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README source link mismatch for {relative}")
    if len(PORTS) != 10:
        issues.append("the inventory must enumerate all ten supported languages")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("static package inventory issues: " + "; ".join(problems))
    print("binary_divisibility_by_three_dfa: ten ports and package artifacts are present")
