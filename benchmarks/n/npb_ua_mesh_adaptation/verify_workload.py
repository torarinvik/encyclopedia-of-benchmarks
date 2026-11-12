"""Static package checks for the bounded NAS UA adaptation profile."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": ROOT / "c/n/npb_ua_mesh_adaptation.c",
    "c3": ROOT / "c3/n/npb_ua_mesh_adaptation.c3",
    "cpp": ROOT / "cpp/n/npb_ua_mesh_adaptation.cpp",
    "elisa": ROOT / "elisa/n/npb_ua_mesh_adaptation.elisa",
    "mojo": ROOT / "mojo/n/npb_ua_mesh_adaptation.mojo",
    "nim": ROOT / "nim/n/npb_ua_mesh_adaptation.nim",
    "odin": ROOT / "odin/n/npb_ua_mesh_adaptation.odin",
    "rust": ROOT / "rust/n/npb_ua_mesh_adaptation.rs",
    "v": ROOT / "v/n/npb_ua_mesh_adaptation.v",
    "zig": ROOT / "zig/n/npb_ua_mesh_adaptation.zig",
}
ORACLES = (
    ROOT / "benchmarks/npb_ua_mesh_adaptation_oracle.py",
    ROOT / "benchmarks/npb_ua_mesh_adaptation_verifier_oracle.py",
)


def verify() -> list[str]:
    errors: list[str] = []
    workload = json.loads((PACKAGE / "workload.json").read_text())
    if workload.get("algorithm") != "npb_ua_mesh_adaptation":
        errors.append("workload algorithm mismatch")
    if workload.get("abi") != "i64_array_float64":
        errors.append("workload ABI mismatch")
    if workload.get("oracle") != "benchmarks/npb_ua_mesh_adaptation_oracle.py":
        errors.append("primary oracle path mismatch")
    if workload.get("independent_oracle") != "benchmarks/npb_ua_mesh_adaptation_verifier_oracle.py":
        errors.append("independent oracle path mismatch")
    cases = workload.get("cases", [])
    if not any(case.get("expected_result") == 220958.0 for case in cases):
        errors.append("root refinement fixture missing")
    if not any(case.get("expected_result") == 240494.0 for case in cases):
        errors.append("movement/coarsening fixture missing")
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
    for name in ("README.md", "RIGHTS.md", "workload.json", "verify_workload.py"):
        if not (PACKAGE / name).is_file():
            errors.append(f"missing package file: {name}")
    return errors


if __name__ == "__main__":
    errors = verify()
    for error in errors:
        print(error)
    if errors:
        raise SystemExit(1)
