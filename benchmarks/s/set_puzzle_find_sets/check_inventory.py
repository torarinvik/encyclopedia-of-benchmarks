"""Static package inventory source; deliberately not executed here."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "set_puzzle_find_sets"
PORTS = {
    "C": ROOT / "c/s/set_puzzle_find_sets.c",
    "C3": ROOT / "c3/s/set_puzzle_find_sets.c3",
    "C++": ROOT / "cpp/s/set_puzzle_find_sets.cpp",
    "Elisa": ROOT / "elisa/s/set_puzzle_find_sets.elisa",
    "Mojo": ROOT / "mojo/s/set_puzzle_find_sets.mojo",
    "Nim": ROOT / "nim/s/set_puzzle_find_sets.nim",
    "Odin": ROOT / "odin/s/set_puzzle_find_sets.odin",
    "Rust": ROOT / "rust/s/set_puzzle_find_sets.rs",
    "V": ROOT / "v/s/set_puzzle_find_sets.v",
    "Zig": ROOT / "zig/s/set_puzzle_find_sets.zig",
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
            issues.append(f"{language} source does not name the ABI symbol")
    elisa_path = PORTS["Elisa"]
    if elisa_path.is_file():
        elisa = elisa_path.read_text(encoding="utf-8")
        if "view[i64]" not in elisa or "mutable view[u8]" not in elisa:
            issues.append("Elisa implementation must use bounded views")
        if "UnsafePointer" in elisa or "ptr " in elisa or "[*]" in elisa:
            issues.append("Elisa must keep raw pointer types out of the implementation")
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"invalid workload JSON: {error}"]
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("workload ABI differs from the package contract")
    contract = workload.get("contract", {})
    if contract.get("maximum_output_bytes") != 536:
        issues.append("maximum output bound differs from the 536-byte proof")
    if workload.get("workspace", {}).get("bytes") != 93:
        issues.append("workspace must account for the 81-byte table and 12 retained codes")
    cases = workload.get("cases", [])
    case_ids = {case.get("id") for case in cases if isinstance(case, dict)}
    for required in ("nine-card-four-set-shape", "twelve-card-six-set-shape",
                     "maximum-parseable-trailing-word", "null-output",
                     "insufficient-output-capacity"):
        if required not in case_ids:
            issues.append(f"missing boundary/workload fixture: {required}")
    return issues


if __name__ == "__main__":
    raise SystemExit("\n".join(check_inventory()))
