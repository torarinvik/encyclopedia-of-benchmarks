"""Read-only static package inventory checks; never run during drafting."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SOURCES = {
    "c": ROOT / "c/s/sieve_of_pritchard.c",
    "c3": ROOT / "c3/s/sieve_of_pritchard.c3",
    "cpp": ROOT / "cpp/s/sieve_of_pritchard.cpp",
    "elisa": ROOT / "elisa/s/sieve_of_pritchard.elisa",
    "mojo": ROOT / "mojo/s/sieve_of_pritchard.mojo",
    "nim": ROOT / "nim/s/sieve_of_pritchard.nim",
    "odin": ROOT / "odin/s/sieve_of_pritchard.odin",
    "rust": ROOT / "rust/s/sieve_of_pritchard.rs",
    "v": ROOT / "v/s/sieve_of_pritchard.v",
    "zig": ROOT / "zig/s/sieve_of_pritchard.zig",
}
EXPECTED_CASES = {
    "minimum-limit", "first-extension", "composite-square-small", "wheel-two",
    "early-prime", "multiple-wheel-growth", "prime-square-boundary", "hundred",
    "prime-limit-997", "maximum-limit", "below-domain", "above-domain",
    "trailing-word", "empty-frame", "null-input", "signed-minimum", "signed-maximum",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    required_files = (
        "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json", "workload.json",
        "primary_oracle.py", "independent_oracle.py", "__init__.py",
        "verify_workload.py", "check_inventory.py",
    )
    for name in required_files:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact {name}")
    for language, path in SOURCES.items():
        if not path.is_file():
            issues.append(f"missing {path.relative_to(ROOT)}")
            continue
        source = path.read_text(encoding="utf-8")
        if "sieve_of_pritchard" not in source:
            issues.append(f"{path.relative_to(ROOT)} lacks the ABI symbol")
        if language == "elisa" and ("view[i64]" not in source or "UnsafePointer" in source):
            issues.append("Elisa should use a bounded input view and no UnsafePointer")
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"invalid package metadata: {error}"]
    expected_paths = {path.relative_to(ROOT).as_posix() for path in SOURCES.values()}
    if (inventory.get("algorithm") != "sieve_of_pritchard"
            or inventory.get("abi") != "i64_array_scalar"
            or set(inventory.get("native_paths", [])) != expected_paths):
        issues.append("inventory identity or ten native source paths are incorrect")
    if (workload.get("algorithm") != "sieve_of_pritchard"
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("input", {}).get("maximum_valid_length") != 1
            or workload.get("input", {}).get("maximum_parseable_length") != 2
            or workload.get("workspace", {}).get("bytes") != 9216):
        issues.append("workload differs from the reviewed ABI and bounds")
    cases = workload.get("cases", [])
    if {case.get("id") for case in cases if isinstance(case, dict)} != EXPECTED_CASES:
        issues.append("workload fixture identifiers differ from the reviewed set")
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object fixture")
            continue
        values, length = case.get("input_values"), case.get("input_length")
        is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int
                or type(is_null) is not bool
                or (is_null and length != 0)
                or (not is_null and length != len(values))):
            issues.append(f"invalid framing for {case.get('id')}")
    return issues


def check_inventory() -> list[str]:
    return static_issues()


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
