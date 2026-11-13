"""Static package inventory and dual-oracle fixture review."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .b.binomial_coefficient_prime_power.independent_oracle import expected_output as independent_output
    from .b.binomial_coefficient_prime_power.primary_oracle import (
        MAX_INPUT_LENGTH,
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
        WORKSPACE_BYTES,
        expected_output as primary_output,
    )
except ImportError:  # Direct import while the benchmarks directory is on sys.path.
    from b.binomial_coefficient_prime_power.independent_oracle import expected_output as independent_output
    from b.binomial_coefficient_prime_power.primary_oracle import (
        MAX_INPUT_LENGTH,
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
        WORKSPACE_BYTES,
        expected_output as primary_output,
    )

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/b/binomial_coefficient_prime_power"
SOURCE_URL = "https://cp-algorithms.com/combinatorics/binomial-coefficients.html#binomial-coefficient-modulo-prime-power"
PORTS = {
    "c": ROOT / "c/b/binomial_coefficient_prime_power.c",
    "c3": ROOT / "c3/b/binomial_coefficient_prime_power.c3",
    "cpp": ROOT / "cpp/b/binomial_coefficient_prime_power.cpp",
    "elisa": ROOT / "elisa/b/binomial_coefficient_prime_power.elisa",
    "mojo": ROOT / "mojo/b/binomial_coefficient_prime_power.mojo",
    "nim": ROOT / "nim/b/binomial_coefficient_prime_power.nim",
    "odin": ROOT / "odin/b/binomial_coefficient_prime_power.odin",
    "rust": ROOT / "rust/b/binomial_coefficient_prime_power.rs",
    "v": ROOT / "v/b/binomial_coefficient_prime_power.v",
    "zig": ROOT / "zig/b/binomial_coefficient_prime_power.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    if workload.get("algorithm") != "binomial_coefficient_prime_power":
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != "binomial_coefficient_prime_power":
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("unexpected ABI")
    if workload.get("source", {}).get("url") != SOURCE_URL:
        issues.append("source URL mismatch")
    input_contract = workload.get("input", {})
    if input_contract.get("maximum_valid_length") != MAX_INPUT_LENGTH:
        issues.append("maximum valid input length mismatch")
    if input_contract.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH:
        issues.append("maximum parseable input length mismatch")
    output_contract = workload.get("output", {})
    if output_contract.get("maximum_bytes") != MAX_OUTPUT_BYTES:
        issues.append("maximum output length mismatch")
    if output_contract.get("output_untouched_on_error") is not True:
        issues.append("workload must promise no output writes on errors")
    if workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES or WORKSPACE_BYTES < MAX_OUTPUT_BYTES:
        issues.append("workspace reservation mismatch or below output capacity")

    cases = workload.get("cases")
    if not isinstance(cases, list):
        return issues + ["workload cases must be a list"]
    has_maximum = False
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        values = case.get("input_values")
        case_id = case.get("id", "<unnamed>")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"fixture input length mismatch: {case_id}")
            continue
        if len(values) > MAX_PARSEABLE_INPUT_LENGTH:
            issues.append(f"fixture exceeds parseable input limit: {case_id}")
            continue
        arguments = {
            "output_capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = (case.get("expected_result"), bytes.fromhex(case.get("expected_output_hex", "")))
        if primary_output(values, **arguments) != expected:
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if independent_output(values, **arguments) != expected:
            issues.append(f"independent oracle fixture mismatch: {case_id}")
        if len(values) == MAX_INPUT_LENGTH and case.get("expected_result") == MAX_OUTPUT_BYTES:
            has_maximum = True

    if not has_maximum:
        issues.append("workload lacks a maximum input/output fixture")
    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif "binomial_coefficient_prime_power" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    if SOURCE_URL not in readme:
        issues.append("README missing algorithm source")
    if "Pascal row" not in readme:
        issues.append("README missing independent oracle description")
    elisa = PORTS["elisa"].read_text(encoding="utf-8") if PORTS["elisa"].is_file() else ""
    if ("input: view[i64]" not in elisa or "output: mutable view[u8]" not in elisa
            or "input: i64&" not in elisa or "output: mutable u8&" not in elisa):
        issues.append("Elisa must use internal safe views and ABI references only in the wrapper")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
