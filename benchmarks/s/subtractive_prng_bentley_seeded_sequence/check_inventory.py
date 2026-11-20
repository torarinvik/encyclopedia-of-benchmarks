"""Static package inventory source; deliberately not executed here."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "subtractive_prng_bentley_seeded_sequence"
PORTS = {
    "C": ROOT / "c/s/subtractive_prng_bentley_seeded_sequence.c",
    "C3": ROOT / "c3/s/subtractive_prng_bentley_seeded_sequence.c3",
    "C++": ROOT / "cpp/s/subtractive_prng_bentley_seeded_sequence.cpp",
    "Elisa": ROOT / "elisa/s/subtractive_prng_bentley_seeded_sequence.elisa",
    "Mojo": ROOT / "mojo/s/subtractive_prng_bentley_seeded_sequence.mojo",
    "Nim": ROOT / "nim/s/subtractive_prng_bentley_seeded_sequence.nim",
    "Odin": ROOT / "odin/s/subtractive_prng_bentley_seeded_sequence.odin",
    "Rust": ROOT / "rust/s/subtractive_prng_bentley_seeded_sequence.rs",
    "V": ROOT / "v/s/subtractive_prng_bentley_seeded_sequence.v",
    "Zig": ROOT / "zig/s/subtractive_prng_bentley_seeded_sequence.zig",
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
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"invalid package JSON: {error}"]
    if workload.get("abi") != "i64_array_bytes_output" or inventory.get("abi") != workload.get("abi"):
        issues.append("workload and inventory ABI must agree")
    if workload.get("contract", {}).get("maximum_output_bytes") != 512:
        issues.append("maximum output bound differs from the 64-word proof")
    if workload.get("workspace", {}).get("bytes") != 440:
        issues.append("workspace must account for the two 55-element i32 buffers")
    if set(inventory.get("native_paths", [])) != {
            str(path.relative_to(ROOT)) for path in PORTS.values()}:
        issues.append("native paths do not match the ten declared ports")
    cases = workload.get("cases", [])
    case_ids = {case.get("id") for case in cases if isinstance(case, dict)}
    for required in ("fresh-seed-short-stream", "zero-length-stream",
                     "maximum-output-bound", "null-output-with-required-bytes",
                     "insufficient-output-capacity"):
        if required not in case_ids:
            issues.append(f"missing workload fixture: {required}")
    for case in cases:
        if isinstance(case, dict) and case.get("oracle_derived_output"):
            if "expected_output_hex" in case:
                issues.append(f"{case.get('id')}: derived output embeds fixture bytes")
    return issues


if __name__ == "__main__":
    raise SystemExit("\n".join(check_inventory()))
