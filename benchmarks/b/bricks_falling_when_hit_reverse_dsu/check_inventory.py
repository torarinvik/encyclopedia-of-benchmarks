"""Static package inventory source; deliberately not executed here."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "bricks_falling_when_hit_reverse_dsu"
PORTS = {
    "C": ROOT / "c/b/bricks_falling_when_hit_reverse_dsu.c",
    "C3": ROOT / "c3/b/bricks_falling_when_hit_reverse_dsu.c3",
    "C++": ROOT / "cpp/b/bricks_falling_when_hit_reverse_dsu.cpp",
    "Elisa": ROOT / "elisa/b/bricks_falling_when_hit_reverse_dsu.elisa",
    "Mojo": ROOT / "mojo/b/bricks_falling_when_hit_reverse_dsu.mojo",
    "Nim": ROOT / "nim/b/bricks_falling_when_hit_reverse_dsu.nim",
    "Odin": ROOT / "odin/b/bricks_falling_when_hit_reverse_dsu.odin",
    "Rust": ROOT / "rust/b/bricks_falling_when_hit_reverse_dsu.rs",
    "V": ROOT / "v/b/bricks_falling_when_hit_reverse_dsu.v",
    "Zig": ROOT / "zig/b/bricks_falling_when_hit_reverse_dsu.zig",
}
FILES = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json",
    "workload.json", "primary_oracle.py", "independent_oracle.py",
    "verify_workload.py", "check_inventory.py", "__init__.py",
)


def check_inventory() -> list[str]:
    issues = [f"missing package file: {name}" for name in FILES
              if not (PACKAGE / name).is_file()]
    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"{language} port lacks the exported ABI symbol")

    elisa_path = PORTS["Elisa"]
    if elisa_path.is_file():
        source = elisa_path.read_text(encoding="utf-8")
        if "view[i64]" not in source or "mutable view[u8]" not in source:
            issues.append("Elisa must use bounded input and output views")
        if "UnsafePointer" in source or "ptr " in source or "[*]" in source:
            issues.append("Elisa must not use raw pointer types")

    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"invalid package JSON: {error}"]
    if workload.get("abi") != "i64_array_bytes_output" or inventory.get("abi") != workload.get("abi"):
        issues.append("workload and inventory ABI must match")
    contract = workload.get("contract", {})
    if contract.get("maximum_valid_input_length") != 99 or contract.get("maximum_parseable_input_length") != 100:
        issues.append("input bounds differ from the 99/100-word proof")
    if contract.get("maximum_output_bytes") != 128:
        issues.append("maximum output differs from the 16-word bound")
    if workload.get("workspace", {}).get("bytes") != 584:
        issues.append("workspace must account for the 64-byte grid and two 65-element i32 arrays")
    if set(inventory.get("native_paths", [])) != {
            str(path.relative_to(ROOT)) for path in PORTS.values()}:
        issues.append("inventory paths do not match the ten declared ports")
    cases = workload.get("cases", [])
    case_ids = {case.get("id") for case in cases if isinstance(case, dict)}
    for required in ("bridge-hit-drops-lower-cluster", "later-hit-on-cell-already-fallen",
                     "empty-cell-hit-produces-zero", "zero-hit-null-output",
                     "maximum-output-all-empty-cells", "repeated-hit-is-invalid",
                     "null-output-required", "insufficient-output-capacity"):
        if required not in case_ids:
            issues.append(f"missing workload case: {required}")
    return issues


if __name__ == "__main__":
    raise SystemExit("\n".join(check_inventory()))
