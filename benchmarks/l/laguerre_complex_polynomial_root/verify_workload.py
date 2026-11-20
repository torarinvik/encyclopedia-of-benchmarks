"""Static package inventory and fixture-contract verifier; not run here."""

from __future__ import annotations

import json
from pathlib import Path

from benchmarks.laguerre_complex_polynomial_root_oracle import (
    ABSOLUTE_TOLERANCE,
    expected_output,
)
from benchmarks.laguerre_complex_polynomial_root_reference import (
    candidate_is_root,
    zero_correction_is_singular,
)

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
ALGORITHM = "laguerre_complex_polynomial_root"
PORTS = {
    "c": (ROOT / "c/l/laguerre_complex_polynomial_root.c", "c/l/laguerre_complex_polynomial_root.c"),
    "c3": (ROOT / "c3/l/laguerre_complex_polynomial_root.c3", "c3/l/laguerre_complex_polynomial_root.c3"),
    "cpp": (ROOT / "cpp/l/laguerre_complex_polynomial_root.cpp", "cpp/l/laguerre_complex_polynomial_root.cpp"),
    "elisa": (ROOT / "elisa/l/laguerre_complex_polynomial_root.elisa", "elisa/l/laguerre_complex_polynomial_root.elisa"),
    "mojo": (ROOT / "mojo/l/laguerre_complex_polynomial_root.mojo", "mojo/l/laguerre_complex_polynomial_root.mojo"),
    "nim": (ROOT / "nim/l/laguerre_complex_polynomial_root.nim", "nim/l/laguerre_complex_polynomial_root.nim"),
    "odin": (ROOT / "odin/l/laguerre_complex_polynomial_root.odin", "odin/l/laguerre_complex_polynomial_root.odin"),
    "rust": (ROOT / "rust/l/laguerre_complex_polynomial_root.rs", "rust/l/laguerre_complex_polynomial_root.rs"),
    "v": (ROOT / "v/l/laguerre_complex_polynomial_root.v", "v/l/laguerre_complex_polynomial_root.v"),
    "zig": (ROOT / "zig/l/laguerre_complex_polynomial_root.zig", "zig/l/laguerre_complex_polynomial_root.zig"),
}


def verify() -> None:
    """Check package files, exact README targets, frame metadata, and fixtures."""
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    if workload.get("algorithm") != ALGORITHM or workload.get("function_symbol") != ALGORITHM:
        raise ValueError("workload algorithm or exported symbol differs")
    if workload.get("abi") != "float64_slice_io":
        raise ValueError("workload ABI differs")
    if workload.get("input", {}).get("maximum_valid_input_length") != 12:
        raise ValueError("maximum valid frame differs")
    if workload.get("input", {}).get("maximum_parseable_input_length") != 13:
        raise ValueError("maximum parseable frame differs")
    for language, (path, relative) in PORTS.items():
        if not path.is_file():
            raise ValueError(f"missing {language} port: {path}")
        if f"](../../../{relative})" not in readme:
            raise ValueError(f"README target missing for {language}")
        source = path.read_text(encoding="utf-8")
        if ALGORITHM not in source:
            raise ValueError(f"exported symbol missing in {language} port")
    if not (PACKAGE / "RIGHTS.md").is_file():
        raise ValueError("missing RIGHTS.md")
    if not (ROOT / "benchmarks/laguerre_complex_polynomial_root_oracle.py").is_file():
        raise ValueError("missing primary Laguerre oracle")
    if not (ROOT / "benchmarks/laguerre_complex_polynomial_root_reference.py").is_file():
        raise ValueError("missing independent root-set reference")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload has no cases")
    case_ids = {case.get("id") for case in cases}
    required_cases = {
        "quadratic-real-root-from-zero-seed",
        "quadratic-complex-root-from-zero-seed",
        "cubic-root-through-laguerre-corrections",
        "maximum-degree-exact-root",
        "coefficient-and-seed-upper-boundaries",
        "maximum-tolerance-and-iteration-cap",
        "stationary-seed-has-zero-correction-denominators",
        "maximum-parseable-trailing-value",
        "undersized-output-buffer",
        "null-output-buffer",
        "invalid-input-precedes-null-output",
    }
    if not required_cases.issubset(case_ids):
        raise ValueError(f"required fixture missing: {sorted(required_cases - case_ids)}")
    for case in cases:
        values = case.get("input_values")
        length = case.get("input_length")
        capacity = case.get("output_capacity", 2)
        status, output = expected_output(
            values,
            capacity,
            output_is_null=case.get("output_is_null", False),
            input_is_null=case.get("input_is_null", False),
            input_length=length,
        )
        if status != case.get("expected_result"):
            raise ValueError(f"oracle status differs for {case.get('id')}")
        if status == 2:
            expected = case.get("expected_output")
            if not isinstance(expected, list) or len(expected) != 2:
                raise ValueError(f"success fixture lacks two expected values: {case.get('id')}")
            if any(abs(float(a) - float(b)) > ABSOLUTE_TOLERANCE for a, b in zip(output, expected)):
                raise ValueError(f"fixture expected root differs for {case.get('id')}")
            if not candidate_is_root(values, output):
                raise ValueError(f"independent root reference rejected {case.get('id')}")
        elif status == -3 and not zero_correction_is_singular(values):
            raise ValueError(f"unrecognized numerical-failure fixture: {case.get('id')}")
