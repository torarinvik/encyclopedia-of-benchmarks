"""Static inventory and oracle-fixture review for bounded GF(2^64) convolution."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .convolution_f2_64_oracle import (
        MAX_M,
        MAX_N,
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        expected_output as primary_output,
    )
    from .convolution_f2_64_independent_oracle import expected_output as independent_output
except ImportError:  # Direct execution from the benchmarks directory.
    from convolution_f2_64_oracle import (
        MAX_M,
        MAX_N,
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        expected_output as primary_output,
    )
    from convolution_f2_64_independent_oracle import expected_output as independent_output

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/c/convolution_f2_64"
TASK_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/convolution/convolution_F_2_64/task.md"
PORTS = {
    "c": ROOT / "c/c/convolution_f2_64.c",
    "c3": ROOT / "c3/c/convolution_f2_64.c3",
    "cpp": ROOT / "cpp/c/convolution_f2_64.cpp",
    "elisa": ROOT / "elisa/c/convolution_f2_64.elisa",
    "mojo": ROOT / "mojo/c/convolution_f2_64.mojo",
    "nim": ROOT / "nim/c/convolution_f2_64.nim",
    "odin": ROOT / "odin/c/convolution_f2_64.odin",
    "rust": ROOT / "rust/c/convolution_f2_64.rs",
    "v": ROOT / "v/c/convolution_f2_64.v",
    "zig": ROOT / "zig/c/convolution_f2_64.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    if workload.get("algorithm") != "convolution_f2_64":
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != "convolution_f2_64":
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("unexpected ABI")
    if workload.get("source", {}).get("task_url") != TASK_URL:
        issues.append("official task URL mismatch")

    contract = workload.get("contract", {})
    if contract.get("local_length_range") != [1, MAX_N] or MAX_M != MAX_N:
        issues.append("bounded input range mismatch")
    if workload.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH:
        issues.append("maximum valid input length mismatch")
    if workload.get("input", {}).get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH:
        issues.append("maximum parseable input length mismatch")
    if workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES:
        issues.append("maximum output size mismatch")
    if workload.get("workspace", {}).get("bytes", 0) < MAX_OUTPUT_BYTES:
        issues.append("workspace reservation is below the output byte bound")

    cases = workload.get("cases")
    if not isinstance(cases, list):
        return issues + ["workload cases must be a list"]
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        values = case.get("input_values")
        name = case.get("id", "<unnamed>")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"fixture input length mismatch: {name}")
            continue
        if len(values) > MAX_PARSEABLE_INPUT_LENGTH:
            issues.append(f"fixture exceeds parseable input bound: {name}")
            continue
        args = {
            "output_capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = (case.get("expected_result"), bytes.fromhex(case.get("expected_output_hex", "")))
        if primary_output(values, **args) != expected:
            issues.append(f"primary oracle fixture mismatch: {name}")
        if independent_output(values, **args) != expected:
            issues.append(f"independent oracle fixture mismatch: {name}")

    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "convolution_f2_64" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    if TASK_URL not in readme or "long division" not in readme.lower():
        issues.append("README missing source or independent algorithm description")
    elisa_path = PORTS["elisa"]
    if elisa_path.is_file():
        source = elisa_path.read_text(encoding="utf-8")
        if ("view[i64]" not in source or "mutable view[u8]" not in source
                or "input: i64&" not in source):
            issues.append("Elisa must use safe internal views and keep refs at the ABI")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
