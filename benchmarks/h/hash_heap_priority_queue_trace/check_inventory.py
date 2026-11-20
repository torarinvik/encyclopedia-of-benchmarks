"""Static inventory validation for the bounded hash-heap package."""
from __future__ import annotations

import json
from pathlib import Path

try:
    from .primary_oracle import MAX_OUTPUT_BYTES, WORKSPACE_BYTES
    from .verify_workload import workload_issues
except ImportError:
    from primary_oracle import MAX_OUTPUT_BYTES, WORKSPACE_BYTES
    from verify_workload import workload_issues

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SYMBOL = "hash_heap_priority_queue_trace"
PORTS = {
    "c": "c/h/hash_heap_priority_queue_trace.c",
    "c3": "c3/h/hash_heap_priority_queue_trace.c3",
    "cpp": "cpp/h/hash_heap_priority_queue_trace.cpp",
    "elisa": "elisa/h/hash_heap_priority_queue_trace.elisa",
    "mojo": "mojo/h/hash_heap_priority_queue_trace.mojo",
    "nim": "nim/h/hash_heap_priority_queue_trace.nim",
    "odin": "odin/h/hash_heap_priority_queue_trace.odin",
    "rust": "rust/h/hash_heap_priority_queue_trace.rs",
    "v": "v/h/hash_heap_priority_queue_trace.v",
    "zig": "zig/h/hash_heap_priority_queue_trace.zig",
}
ARTIFACTS = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py", "check_inventory.py",
)
SOURCE_URLS = (
    "https://xlinux.nist.gov/dads/HTML/hashheap.html",
    "https://xlinux.nist.gov/dads/HTML/linearhash.html",
)


def static_issues() -> list[str]:
    issues = workload_issues()
    for name in ARTIFACTS:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read inventory: {error}"]
    if inventory.get("algorithm") != SYMBOL or inventory.get("abi") != "i64_array_bytes_output":
        issues.append("inventory identity or ABI mismatch")
    if inventory.get("ports") != PORTS:
        issues.append("inventory language paths differ from the ten-port map")
    if inventory.get("bounds") != {
        "maximum_valid_input_words": 131,
        "maximum_parseable_input_words": 132,
        "maximum_output_bytes": MAX_OUTPUT_BYTES,
        "workspace_bytes": WORKSPACE_BYTES,
    }:
        issues.append("inventory bounds differ from the profile")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if "The particular floor mapping" not in readme:
        issues.append("README must identify profile choices separately from DADS")
    for relative in PORTS.values():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing language source: {relative}")
            continue
        if SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"entrypoint missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README port link missing: {relative}")
    for url in SOURCE_URLS:
        if url not in readme or url not in rights:
            issues.append(f"source citation missing: {url}")
    elisa = (ROOT / PORTS["elisa"]).read_text(encoding="utf-8") if (ROOT / PORTS["elisa"]).is_file() else ""
    if "UnsafePointer" in elisa or "*i64" in elisa:
        issues.append("Elisa implementation should use bounded views internally")
    return issues


def check_inventory() -> list[str]:
    return static_issues()


if __name__ == "__main__":
    issues = static_issues()
    if issues:
        raise SystemExit("\n".join(issues))
    print("static hash-heap inventory")
