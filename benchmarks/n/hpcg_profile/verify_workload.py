"""Static package checks for the bounded HPCG profile; runs no benchmark code."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": ROOT / "c/n/hpcg_profile.c",
    "c3": ROOT / "c3/n/hpcg_profile.c3",
    "cpp": ROOT / "cpp/n/hpcg_profile.cpp",
    "elisa": ROOT / "elisa/n/hpcg_profile.elisa",
    "mojo": ROOT / "mojo/n/hpcg_profile.mojo",
    "nim": ROOT / "nim/n/hpcg_profile.nim",
    "odin": ROOT / "odin/n/hpcg_profile.odin",
    "rust": ROOT / "rust/n/hpcg_profile.rs",
    "v": ROOT / "v/n/hpcg_profile.v",
    "zig": ROOT / "zig/n/hpcg_profile.zig",
}
ORACLES = (PACKAGE / "primary_oracle.py", PACKAGE / "independent_oracle.py")


def verify() -> list[str]:
    errors: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"workload cannot be read: {error}"]
    if workload.get("algorithm") != "hpcg_profile":
        errors.append("workload algorithm mismatch")
    if workload.get("abi") != "i64_array_bytes_output":
        errors.append("workload ABI mismatch")
    if workload.get("oracle") != "benchmarks/n/hpcg_profile/primary_oracle.py":
        errors.append("primary oracle path mismatch")
    if workload.get("independent_oracle") != "benchmarks/n/hpcg_profile/independent_oracle.py":
        errors.append("independent oracle path mismatch")
    if workload.get("output", {}).get("kind") != "float64_vector":
        errors.append("output must declare its packed binary64 vector")
    if workload.get("workspace", {}).get("bytes") != 264:
        errors.append("output workspace must match the maximum packed binary64 result")
    output = workload.get("output", {})
    if (output.get("maximum_output_bytes") != 264
            or output.get("absolute_tolerance") != 1e-8
            or output.get("relative_tolerance") != 1e-8):
        errors.append("binary64 output bound or tolerance differs from the profile contract")
    if workload.get("source", {}).get("repository_url") != "https://github.com/hpcg-benchmark/hpcg/blob/master/README.md":
        errors.append("HPCG source provenance missing")
    cases = workload.get("cases", [])
    if len(cases) < 5:
        errors.append("workload fixtures are incomplete")
    for case in cases:
        values = case.get("input_values", [])
        if case.get("input_length") != len(values):
            errors.append(f"fixture length mismatch: {case.get('id')}")
        expected = case.get("expected_output", [])
        if case.get("expected_result", -1) >= 0 and case.get("expected_result") != 8 * len(expected):
            errors.append(f"fixture result/output mismatch: {case.get('id')}")
    for language, path in PORTS.items():
        if not path.is_file():
            errors.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "hpcg_profile" not in path.read_text(encoding="utf-8"):
            errors.append(f"port symbol missing: {path.relative_to(ROOT)}")
    for path in ORACLES:
        if not path.is_file():
            errors.append(f"missing oracle: {path.name}")
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
