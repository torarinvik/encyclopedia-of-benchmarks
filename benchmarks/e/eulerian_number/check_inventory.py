"""Static artifact and source-presence check; never runs language ports."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
STEM = "eulerian_number"
PORTS = {
    "C": "c/e/eulerian_number.c",
    "C3": "c3/e/eulerian_number.c3",
    "C++": "cpp/e/eulerian_number.cpp",
    "Elisa": "elisa/e/eulerian_number.elisa",
    "Mojo": "mojo/e/eulerian_number.mojo",
    "Nim": "nim/e/eulerian_number.nim",
    "Odin": "odin/e/eulerian_number.odin",
    "Rust": "rust/e/eulerian_number.rs",
    "V": "v/e/eulerian_number.v",
    "Zig": "zig/e/eulerian_number.zig",
}
NULL_GUARDS = {
    "C": "values == NULL",
    "C3": "values == null",
    "C++": "values == nullptr",
    "Elisa": "values.is_null()",
    "Mojo": "UnsafePointer[Int64, ImmutAnyOrigin]()",
    "Nim": "values.isNil",
    "Odin": "values == nil",
    "Rust": "values.is_null()",
    "V": "values == nil",
    "Zig": "values == null",
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
            or workload.get("abi") != "i64_array_scalar"):
        issues.append("workload identity differs from the exported scalar contract")
    if "No OI Wiki source code" not in rights or "CC BY-SA 4.0" not in rights:
        issues.append("rights note omits source-license and clean-room boundaries")

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
    if "view[i64]" not in elisa or "values[0:length]" not in elisa:
        issues.append("Elisa port should slice the ABI input into a bounded view")
    if len(PORTS) != 10:
        issues.append("inventory must enumerate all ten supported languages")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("static package inventory issues: " + "; ".join(problems))
    print("eulerian_number: ten ports and package artifacts are present")
