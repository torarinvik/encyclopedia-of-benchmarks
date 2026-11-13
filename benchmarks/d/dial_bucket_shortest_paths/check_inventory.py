"""Static package, workload, oracle, and ten-port inventory review."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
from types import ModuleType

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "dial_bucket_shortest_paths"

PORTS = {
    "C": ROOT / "c/d/dial_bucket_shortest_paths.c",
    "C3": ROOT / "c3/d/dial_bucket_shortest_paths.c3",
    "C++": ROOT / "cpp/d/dial_bucket_shortest_paths.cpp",
    "Elisa": ROOT / "elisa/d/dial_bucket_shortest_paths.elisa",
    "Mojo": ROOT / "mojo/d/dial_bucket_shortest_paths.mojo",
    "Nim": ROOT / "nim/d/dial_bucket_shortest_paths.nim",
    "Odin": ROOT / "odin/d/dial_bucket_shortest_paths.odin",
    "Rust": ROOT / "rust/d/dial_bucket_shortest_paths.rs",
    "V": ROOT / "v/d/dial_bucket_shortest_paths.v",
    "Zig": ROOT / "zig/d/dial_bucket_shortest_paths.zig",
}


def _load(name: str, path: Path) -> ModuleType:
    spec = importlib.util.spec_from_file_location(f"_dial_bucket_{name}", path)
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load oracle module at {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_primary = _load("primary", PACKAGE / "primary_oracle.py")
_independent = _load("independent", PACKAGE / "independent_oracle.py")
MAX_VALID_INPUT_LENGTH = _primary.MAX_VALID_INPUT_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = _primary.MAX_PARSEABLE_INPUT_LENGTH
MAX_OUTPUT_BYTES = _primary.MAX_OUTPUT_BYTES
WORKSPACE_BYTES = _primary.WORKSPACE_BYTES


def check_inventory() -> list[str]:
    issues: list[str] = []
    required_files = (
        "README.md", "RIGHTS.md", "workload.json",
        "primary_oracle.py", "independent_oracle.py",
    )
    for name in required_files:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
            continue
        if SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"{language} port does not declare {SYMBOL}")

    elisa_path = PORTS["Elisa"]
    if elisa_path.is_file():
        source = elisa_path.read_text(encoding="utf-8")
        if "view[i64]" not in source or "mutable view[u8]" not in source:
            issues.append("Elisa must use safe views internally")
        if "input: i64&" not in source or "output: mutable u8&" not in source:
            issues.append("Elisa must confine references to the exported ABI")
        if "UnsafePointer" in source or "ptr " in source:
            issues.append("Elisa must not use internal raw pointers")

    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"invalid workload JSON: {error}"]
    if workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL:
        issues.append("workload algorithm and symbol must match the package")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("workload ABI must be i64_array_bytes_output")

    input_spec = workload.get("input", {})
    if (input_spec.get("encoding") != "[N,M,source,(u,v,weight)*M]"
            or input_spec.get("N_range") != [1, 16]
            or input_spec.get("M_range") != [0, 64]
            or input_spec.get("edge_weight_range") != [0, 8]
            or input_spec.get("vertex_ids") != "0..N-1"
            or input_spec.get("source_rule") != "0 <= source < N"
            or input_spec.get("graph_semantics")
            != "Directed; self-loops, parallel edges, and zero-weight edges are valid."
            or input_spec.get("exact_length") != "3+3*M"
            or input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_spec.get("invalid_input_result") != -1
            or input_spec.get("null_input_result") != -1):
        issues.append("input bounds or directed-graph contract differs from the oracle")
    output_spec = workload.get("output", {})
    if (output_spec.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or output_spec.get("invalid_input_result") != -1
            or output_spec.get("null_output_result") != -2
            or output_spec.get("insufficient_capacity_result") != -2
            or output_spec.get("output_untouched_on_error") is not True):
        issues.append("output bound differs from the primary oracle")
    if workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES:
        issues.append("workspace bound differs from the primary oracle")
    details = workload.get("algorithm_details", {})
    if (details.get("ring_bucket_count") != 9
            or details.get("maximum_finite_distance") != 120
            or _primary.BUCKET_COUNT != 9
            or _primary.MAX_DISTANCE != 120):
        issues.append("nine-slot ring or maximum-distance metadata differs")

    cases = workload.get("cases", [])
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases must be a nonempty array"]
    found_maximum = False
    found_parseable = False
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        case_id = case.get("id", "<unnamed>")
        values = case.get("input_values", [])
        if not isinstance(values, list):
            issues.append(f"{case_id}: input_values must be an array")
            continue
        if not case.get("input_is_null", False) and case.get("input_length") != len(values):
            issues.append(f"{case_id}: declared input length differs from its values")
        if case_id == "maximum-input-distance-and-output":
            found_maximum = len(values) == MAX_VALID_INPUT_LENGTH and values[:3] == [16, 64, 0]
        if case_id == "maximum-parseable-trailing-word":
            found_parseable = len(values) == MAX_PARSEABLE_INPUT_LENGTH and case.get("expected_result") == -1
        try:
            payload = bytes.fromhex(case.get("expected_output_hex", ""))
        except (TypeError, ValueError):
            issues.append(f"{case_id}: expected output is not valid hexadecimal")
            continue
        result = case.get("expected_result")
        if isinstance(result, int) and result >= 0 and len(payload) != result:
            issues.append(f"{case_id}: result differs from output byte count")
        primary = _primary.expected_output(
            values, capacity=case.get("output_capacity"),
            output_is_null=case.get("output_is_null", False),
            input_is_null=case.get("input_is_null", False),
            input_length=case.get("input_length"),
        )
        independent = _independent.expected_output(
            values, capacity=case.get("output_capacity"),
            output_is_null=case.get("output_is_null", False),
            input_is_null=case.get("input_is_null", False),
            input_length=case.get("input_length"),
        )
        expected = (result, payload)
        if primary != expected:
            issues.append(f"{case_id}: primary oracle differs from fixture")
        if independent != expected:
            issues.append(f"{case_id}: Floyd–Warshall oracle differs from fixture")
    if not found_maximum:
        issues.append("missing maximum valid 195-word input/output fixture")
    if not found_parseable:
        issues.append("missing maximum parseable trailing-word fixture")

    return issues


static_issues = check_inventory


if __name__ == "__main__":
    failures = check_inventory()
    if failures:
        raise SystemExit("\n".join(failures))
