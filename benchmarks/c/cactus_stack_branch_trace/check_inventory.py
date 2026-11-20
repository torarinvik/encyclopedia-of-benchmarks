"""Static source and workload inventory; intentionally not executed here."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .verify_workload import workload_issues
except ImportError:
    from verify_workload import workload_issues

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": (ROOT / "c/c/cactus_stack_branch_trace.c", "c/cactus_stack_branch_trace.c"),
    "c3": (ROOT / "c3/c/cactus_stack_branch_trace.c3", "c3/cactus_stack_branch_trace.c3"),
    "cpp": (ROOT / "cpp/c/cactus_stack_branch_trace.cpp", "cpp/cactus_stack_branch_trace.cpp"),
    "elisa": (ROOT / "elisa/c/cactus_stack_branch_trace.elisa", "elisa/c/cactus_stack_branch_trace.elisa"),
    "mojo": (ROOT / "mojo/c/cactus_stack_branch_trace.mojo", "mojo/c/cactus_stack_branch_trace.mojo"),
    "nim": (ROOT / "nim/c/cactus_stack_branch_trace.nim", "nim/c/cactus_stack_branch_trace.nim"),
    "odin": (ROOT / "odin/c/cactus_stack_branch_trace.odin", "odin/c/cactus_stack_branch_trace.odin"),
    "rust": (ROOT / "rust/c/cactus_stack_branch_trace.rs", "rust/c/cactus_stack_branch_trace.rs"),
    "v": (ROOT / "v/c/cactus_stack_branch_trace.v", "v/c/cactus_stack_branch_trace.v"),
    "zig": (ROOT / "zig/c/cactus_stack_branch_trace.zig", "zig/c/cactus_stack_branch_trace.zig"),
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package metadata: {error}"]
    if (inventory.get("algorithm") != "cactus_stack_branch_trace"
            or inventory.get("abi") != "i64_array_bytes_output"
            or inventory.get("maximum_valid_input_words") != 145
            or inventory.get("maximum_parseable_input_words") != 146
            or inventory.get("maximum_output_bytes") != 768
            or inventory.get("workspace_bytes") != 4096):
        issues.append("inventory bounds or identity mismatch")
    for language, (path, relative) in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} source: {relative}")
        elif "cactus_stack_branch_trace" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {relative}")
        if f"](../../../{relative})" not in (PACKAGE / "README.md").read_text(encoding="utf-8"):
            issues.append(f"missing README source link: {language}")
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json",
                 "primary_oracle.py", "independent_oracle.py", "workload.json",
                 "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    issues.extend(workload_issues(workload))
    return issues


def check_inventory() -> None:
    issues = static_issues()
    if issues:
        raise ValueError("; ".join(issues))


if __name__ == "__main__":
    check_inventory()
