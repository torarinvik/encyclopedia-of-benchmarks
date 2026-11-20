"""Static source and metadata checker for the bounded bitset benchmark."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
ALGORITHM = "bitset_xor_shift_trace"
LANGUAGE_FILES = {
    "c": f"c/b/{ALGORITHM}.c",
    "c3": f"c3/b/{ALGORITHM}.c3",
    "cpp": f"cpp/b/{ALGORITHM}.cpp",
    "elisa": f"elisa/b/{ALGORITHM}.elisa",
    "mojo": f"mojo/b/{ALGORITHM}.mojo",
    "nim": f"nim/b/{ALGORITHM}.nim",
    "odin": f"odin/b/{ALGORITHM}.odin",
    "rust": f"rust/b/{ALGORITHM}.rs",
    "v": f"v/b/{ALGORITHM}.v",
    "zig": f"zig/b/{ALGORITHM}.zig",
}
PACKAGE_FILES = (
    "README.md", "RIGHTS.md", "INVENTORY.json", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    "check_inventory.py",
)


def inventory_errors() -> list[str]:
    errors = [str(PACKAGE / name) for name in PACKAGE_FILES if not (PACKAGE / name).is_file()]
    errors.extend(path for path in LANGUAGE_FILES.values() if not (ROOT / path).is_file())
    try:
        metadata = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return errors + ["package metadata or workload is unreadable or invalid JSON"]
    if metadata.get("algorithm") != ALGORITHM or workload.get("algorithm") != ALGORITHM:
        errors.append("package metadata does not match the algorithm symbol")
    if workload.get("abi") != "i64_array_bytes_output":
        errors.append("workload ABI does not match the byte-output interface")
    if metadata.get("languages") != LANGUAGE_FILES:
        errors.append("inventory language paths do not match the supported ports")
    return errors
