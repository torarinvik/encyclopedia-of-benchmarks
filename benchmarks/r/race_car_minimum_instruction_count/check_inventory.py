"""Static inventory helper; deliberately not executed during source drafting."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "race_car_minimum_instruction_count"
PORTS = {
    "C": ROOT / "c/r/race_car_minimum_instruction_count.c",
    "C3": ROOT / "c3/r/race_car_minimum_instruction_count.c3",
    "C++": ROOT / "cpp/r/race_car_minimum_instruction_count.cpp",
    "Elisa": ROOT / "elisa/r/race_car_minimum_instruction_count.elisa",
    "Mojo": ROOT / "mojo/r/race_car_minimum_instruction_count.mojo",
    "Nim": ROOT / "nim/r/race_car_minimum_instruction_count.nim",
    "Odin": ROOT / "odin/r/race_car_minimum_instruction_count.odin",
    "Rust": ROOT / "rust/r/race_car_minimum_instruction_count.rs",
    "V": ROOT / "v/r/race_car_minimum_instruction_count.v",
    "Zig": ROOT / "zig/r/race_car_minimum_instruction_count.zig",
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
            issues.append(f"{language} port lacks the exported symbol")
    elisa_path = PORTS["Elisa"]
    if elisa_path.is_file():
        source = elisa_path.read_text(encoding="utf-8")
        if "view[i64]" not in source:
            issues.append("Elisa input should use a bounded i64 view")
        if "UnsafePointer" in source or "ptr " in source or "[*]" in source:
            issues.append("Elisa should not use raw pointer types")
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"invalid package JSON: {error}"]
    if workload.get("abi") != "i64_array_scalar" or inventory.get("abi") != workload.get("abi"):
        issues.append("workload and inventory ABI must match")
    contract = workload.get("contract", {})
    if contract.get("maximum_valid_input_words") != 1 or contract.get("maximum_parseable_input_words") != 2:
        issues.append("input bounds differ from the 1/2-word contract")
    if workload.get("workspace", {}).get("bytes") != 512:
        issues.append("workspace must include the fixed 128-element i32 table")
    if set(inventory.get("native_paths", [])) != {
            str(path.relative_to(ROOT)) for path in PORTS.values()}:
        issues.append("inventory paths do not match the ten declared ports")
    return issues


if __name__ == "__main__":
    raise SystemExit("\n".join(check_inventory()))
