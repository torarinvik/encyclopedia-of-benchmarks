"""Static artifact inventory checker; intentionally not run during authoring."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
REPO_ROOT = PACKAGE.parents[2]
ALGORITHM = "schuler_randomized_general_cnf_sat"
LANGUAGE_FILES = {
    "c": f"c/s/{ALGORITHM}.c",
    "c3": f"c3/s/{ALGORITHM}.c3",
    "cpp": f"cpp/s/{ALGORITHM}.cpp",
    "elisa": f"elisa/s/{ALGORITHM}.elisa",
    "mojo": f"mojo/s/{ALGORITHM}.mojo",
    "nim": f"nim/s/{ALGORITHM}.nim",
    "odin": f"odin/s/{ALGORITHM}.odin",
    "rust": f"rust/s/{ALGORITHM}.rs",
    "v": f"v/s/{ALGORITHM}.v",
    "zig": f"zig/s/{ALGORITHM}.zig",
}
PACKAGE_FILES = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "check_inventory.py",
)


def inventory_errors() -> list[str]:
    errors = [str(PACKAGE / name) for name in PACKAGE_FILES if not (PACKAGE / name).is_file()]
    errors.extend(path for path in LANGUAGE_FILES.values() if not (REPO_ROOT / path).is_file())
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return errors + ["workload.json is unreadable or invalid JSON"]
    if workload.get("algorithm") != ALGORITHM or workload.get("abi") != "i64_array_bytes_output":
        errors.append("workload metadata does not match the package contract")
    return errors


if __name__ == "__main__":
    problems = inventory_errors()
    if problems:
        raise SystemExit("\n".join(problems))
