"""Static package inventory; intentionally does not compile or run native ports."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = {
    "C": ROOT / "c/b/base58check_encode.c",
    "C3": ROOT / "c3/b/base58check_encode.c3",
    "C++": ROOT / "cpp/b/base58check_encode.cpp",
    "Elisa": ROOT / "elisa/b/base58check_encode.elisa",
    "Mojo": ROOT / "mojo/b/base58check_encode.mojo",
    "Nim": ROOT / "nim/b/base58check_encode.nim",
    "Odin": ROOT / "odin/b/base58check_encode.odin",
    "Rust": ROOT / "rust/b/base58check_encode.rs",
    "V": ROOT / "v/b/base58check_encode.v",
    "Zig": ROOT / "zig/b/base58check_encode.zig",
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
            continue
        if "base58check_encode" not in path.read_text(encoding="utf-8"):
            issues.append(f"{language} source does not name the ABI symbol")
    elisa_path = PORTS["Elisa"]
    if elisa_path.is_file():
        elisa_source = elisa_path.read_text(encoding="utf-8")
        if "input: view[i64]" not in elisa_source or "output: mutable view[u8]" not in elisa_source:
            issues.append("Elisa must keep its implementation on safe bounded views")
        if "UnsafePointer" in elisa_source or "ptr " in elisa_source:
            issues.append("Elisa must keep pointer types out of the implementation")
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"invalid workload JSON: {error}"]
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("workload ABI differs from the declared output family")
    if workload.get("workspace", {}).get("bytes") != 826:
        issues.append("workspace does not include the largest fixed native scratch set")
    if workload.get("input", {}).get("maximum_valid_length") != 34 or \
            workload.get("input", {}).get("maximum_parseable_length") != 35:
        issues.append("workload input bounds differ from the package contract")
    case_ids = {case.get("id") for case in workload.get("cases", []) if isinstance(case, dict)}
    for required in ("empty-payload", "maximum-payload-maximum-encoded-length",
                     "maximum-parseable-trailing-word", "null-output"):
        if required not in case_ids:
            issues.append(f"missing boundary fixture: {required}")
    return issues


if __name__ == "__main__":
    raise SystemExit("\n".join(check_inventory()))
