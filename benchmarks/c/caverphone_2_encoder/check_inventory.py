"""Static source inventory and workload review for Caverphone 2.0."""

from __future__ import annotations

import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[3]
BENCHMARKS = ROOT / "benchmarks"
if str(BENCHMARKS) not in sys.path:
    sys.path.insert(0, str(BENCHMARKS))

from caverphone_2_encoder_oracle import (  # noqa: E402
    MAX_INPUT_LENGTH,
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_TEXT_LENGTH,
    expected_output as primary_output,
)
from caverphone_2_encoder_independent_oracle import (  # noqa: E402
    expected_output as independent_output,
)

PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": (ROOT / "c/c/caverphone_2_encoder.c", "c/c/caverphone_2_encoder.c"),
    "c3": (ROOT / "c3/c/caverphone_2_encoder.c3", "c3/c/caverphone_2_encoder.c3"),
    "cpp": (ROOT / "cpp/c/caverphone_2_encoder.cpp", "cpp/c/caverphone_2_encoder.cpp"),
    "elisa": (ROOT / "elisa/c/caverphone_2_encoder.elisa", "elisa/c/caverphone_2_encoder.elisa"),
    "mojo": (ROOT / "mojo/c/caverphone_2_encoder.mojo", "mojo/c/caverphone_2_encoder.mojo"),
    "nim": (ROOT / "nim/c/caverphone_2_encoder.nim", "nim/c/caverphone_2_encoder.nim"),
    "odin": (ROOT / "odin/c/caverphone_2_encoder.odin", "odin/c/caverphone_2_encoder.odin"),
    "rust": (ROOT / "rust/c/caverphone_2_encoder.rs", "rust/c/caverphone_2_encoder.rs"),
    "v": (ROOT / "v/c/caverphone_2_encoder.v", "v/c/caverphone_2_encoder.v"),
    "zig": (ROOT / "zig/c/caverphone_2_encoder.zig", "zig/c/caverphone_2_encoder.zig"),
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    if workload.get("algorithm") != "caverphone_2_encoder":
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != "caverphone_2_encoder":
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("unexpected ABI")
    input_spec = workload.get("input", {})
    if input_spec.get("text_length_range") != [0, MAX_TEXT_LENGTH]:
        issues.append("text length range mismatch")
    if (input_spec.get("array_length") != "1 + text_length"
            or input_spec.get("maximum_length") != MAX_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH):
        issues.append("input frame bounds mismatch")
    output_spec = workload.get("output", {})
    if output_spec.get("maximum_bytes") != MAX_OUTPUT_BYTES:
        issues.append("output byte bound mismatch")
    if workload.get("workspace") != {"bytes": MAX_OUTPUT_BYTES}:
        issues.append("output workspace mismatch")

    cases = workload.get("cases", [])
    if not isinstance(cases, list):
        return issues + ["workload cases must be a list"]
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        case_id = case.get("id", "<unnamed>")
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"fixture input length mismatch: {case_id}")
            continue
        arguments = {
            "output_capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        try:
            expected = (case.get("expected_result"), bytes.fromhex(case.get("expected_output_hex", "")))
        except (TypeError, ValueError):
            issues.append(f"invalid expected output encoding: {case_id}")
            continue
        if primary_output(values, **arguments) != expected:
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if independent_output(values, **arguments) != expected:
            issues.append(f"independent oracle fixture mismatch: {case_id}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    for language, (path, relative) in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
            continue
        source = path.read_text(encoding="utf-8")
        if "caverphone_2_encoder" not in source:
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")
        target = f"](../../../{relative})"
        if target not in readme:
            issues.append(f"README link mismatch for {language}: {relative}")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")
    if "ctp150804.pdf" not in readme or "ctp150804.pdf" not in (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8"):
        issues.append("specification provenance link is missing")
    elisa = PORTS["elisa"][0]
    if elisa.is_file():
        source = elisa.read_text(encoding="utf-8")
        if ("input: view[i64]" not in source or "output: mutable view[u8]" not in source
                or "input: i64&" not in source or "output: mutable u8&" not in source):
            issues.append("Elisa must use views internally and references only at its exported ABI")
    return issues


def verify() -> None:
    """Raise if package files or fixture expectations are incomplete."""
    issues = static_issues()
    if issues:
        raise ValueError("\n".join(issues))
