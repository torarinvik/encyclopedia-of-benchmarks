"""Static artifact/source-presence check; never runs language ports."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
STEM = "fractional_programming_ratio_knapsack_binary_search"
PORTS = {
    "C": "c/f/fractional_programming_ratio_knapsack_binary_search.c",
    "C3": "c3/f/fractional_programming_ratio_knapsack_binary_search.c3",
    "C++": "cpp/f/fractional_programming_ratio_knapsack_binary_search.cpp",
    "Elisa": "elisa/f/fractional_programming_ratio_knapsack_binary_search.elisa",
    "Mojo": "mojo/f/fractional_programming_ratio_knapsack_binary_search.mojo",
    "Nim": "nim/f/fractional_programming_ratio_knapsack_binary_search.nim",
    "Odin": "odin/f/fractional_programming_ratio_knapsack_binary_search.odin",
    "Rust": "rust/f/fractional_programming_ratio_knapsack_binary_search.rs",
    "V": "v/f/fractional_programming_ratio_knapsack_binary_search.v",
    "Zig": "zig/f/fractional_programming_ratio_knapsack_binary_search.zig",
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
    "Zig": "input_opt orelse return -1",
}
REQUIRED_ARTIFACTS = (
    "RESERVATION.md", "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py", "check_inventory.py",
)


def static_issues() -> list[str]:
    issues = [f"missing package artifact: {name}" for name in REQUIRED_ARTIFACTS
              if not (PACKAGE / name).is_file()]
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read package metadata: {error}"]
    if (workload.get("algorithm") != STEM or workload.get("function_symbol") != STEM
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("workload identity differs from the scalar export")
    if "CC BY-SA 4.0" not in rights or "No source code" not in rights:
        issues.append("rights note omits license and clean-room boundaries")

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
            issues.append(f"export symbol is missing from {relative}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"null-input guard is missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README source link mismatch for {relative}")
    elisa = (ROOT / PORTS["Elisa"]).read_text(encoding="utf-8")
    if "view[i64]" not in elisa or "input[0:length]" not in elisa:
        issues.append("Elisa port should use a bounded view after its ABI checks")
    if len(PORTS) != 10:
        issues.append("inventory must enumerate all ten supported languages")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("static inventory issues: " + "; ".join(problems))
    print("fractional_programming_ratio_knapsack_binary_search: package artifacts are present")
