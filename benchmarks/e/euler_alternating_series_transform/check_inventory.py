"""Static package inventory source; deliberately not executed here."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = {
    "C": ROOT / "c/e/euler_alternating_series_transform.c",
    "C3": ROOT / "c3/e/euler_alternating_series_transform.c3",
    "C++": ROOT / "cpp/e/euler_alternating_series_transform.cpp",
    "Elisa": ROOT / "elisa/e/euler_alternating_series_transform.elisa",
    "Mojo": ROOT / "mojo/e/euler_alternating_series_transform.mojo",
    "Nim": ROOT / "nim/e/euler_alternating_series_transform.nim",
    "Odin": ROOT / "odin/e/euler_alternating_series_transform.odin",
    "Rust": ROOT / "rust/e/euler_alternating_series_transform.rs",
    "V": ROOT / "v/euler_alternating_series_transform.v",
    "Zig": ROOT / "zig/euler_alternating_series_transform.zig",
}
FILES = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json",
    "workload.json", "primary_oracle.py", "independent_oracle.py",
    "verify_workload.py", "check_inventory.py", "__init__.py",
)


def check_inventory() -> list[str]:
    issues = [f"missing package file: {name}" for name in FILES
              if not (PACKAGE / name).is_file()]
    symbol = "euler_alternating_series_transform"
    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
            continue
        if symbol not in path.read_text(encoding="utf-8"):
            issues.append(f"{language} source does not name the ABI symbol")
    elisa = PORTS["Elisa"]
    if elisa.is_file():
        source = elisa.read_text(encoding="utf-8")
        if "view[i64]" not in source or "mutable view[u8]" not in source:
            issues.append("Elisa implementation must use bounded views")
        if "UnsafePointer" in source or "ptr " in source:
            issues.append("Elisa must keep pointer types out of the implementation")
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"invalid workload JSON: {error}"]
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("workload ABI differs from the package contract")
    if workload.get("contract", {}).get("maximum_output_bytes") != 16:
        issues.append("maximum output bound differs from the native profile")
    if workload.get("workspace", {}).get("bytes") != 0:
        issues.append("workspace should reflect the scalar-only native profile")
    case_ids = {case.get("id") for case in workload.get("cases", []) if isinstance(case, dict)}
    for required in ("single-term-half", "maximum-terms-alternating-values",
                     "maximum-parseable-trailing-word", "truncated-frame", "null-output"):
        if required not in case_ids:
            issues.append(f"missing boundary fixture: {required}")
    return issues


if __name__ == "__main__":
    raise SystemExit("\n".join(check_inventory()))
