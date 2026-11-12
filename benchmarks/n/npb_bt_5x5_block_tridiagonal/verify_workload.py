"""Static package checks for the bounded NAS BT block-line profile."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": ROOT / "c/n/npb_bt_5x5_block_tridiagonal.c",
    "c3": ROOT / "c3/n/npb_bt_5x5_block_tridiagonal.c3",
    "cpp": ROOT / "cpp/n/npb_bt_5x5_block_tridiagonal.cpp",
    "elisa": ROOT / "elisa/n/npb_bt_5x5_block_tridiagonal.elisa",
    "mojo": ROOT / "mojo/n/npb_bt_5x5_block_tridiagonal.mojo",
    "nim": ROOT / "nim/n/npb_bt_5x5_block_tridiagonal.nim",
    "odin": ROOT / "odin/n/npb_bt_5x5_block_tridiagonal.odin",
    "rust": ROOT / "rust/n/npb_bt_5x5_block_tridiagonal.rs",
    "v": ROOT / "v/n/npb_bt_5x5_block_tridiagonal.v",
    "zig": ROOT / "zig/n/npb_bt_5x5_block_tridiagonal.zig",
}
ORACLES = (
    ROOT / "benchmarks/npb_bt_5x5_block_tridiagonal_oracle.py",
    ROOT / "benchmarks/npb_bt_5x5_block_tridiagonal_verifier_oracle.py",
)


def verify() -> list[str]:
    errors: list[str] = []
    workload = json.loads((PACKAGE / "workload.json").read_text())
    if workload.get("algorithm") != "npb_bt_5x5_block_tridiagonal":
        errors.append("workload algorithm mismatch")
    if workload.get("abi") != "i64_array_float64":
        errors.append("workload ABI mismatch")
    if workload.get("oracle") != "benchmarks/npb_bt_5x5_block_tridiagonal_oracle.py":
        errors.append("primary oracle path mismatch")
    if workload.get("independent_oracle") != "benchmarks/npb_bt_5x5_block_tridiagonal_verifier_oracle.py":
        errors.append("independent oracle path mismatch")
    cases = workload.get("cases", [])
    if not any(case.get("expected_result") == 105.0 for case in cases):
        errors.append("known-solution fixture missing")
    for case in cases:
        values = case.get("input_values", [])
        if case.get("input_length") != len(values):
            errors.append(f"fixture length mismatch: {case.get('id')}")
    for language, path in PORTS.items():
        if not path.is_file():
            errors.append(f"missing {language} port: {path.relative_to(ROOT)}")
    for path in ORACLES:
        if not path.is_file():
            errors.append(f"missing oracle: {path.relative_to(ROOT)}")
    for name in (
        "README.md", "RIGHTS.md", "workload.json", "verify_workload.py",
    ):
        if not (PACKAGE / name).is_file():
            errors.append(f"missing package file: {name}")
    return errors


if __name__ == "__main__":
    for error in verify():
        print(error)
    if verify():
        raise SystemExit(1)
