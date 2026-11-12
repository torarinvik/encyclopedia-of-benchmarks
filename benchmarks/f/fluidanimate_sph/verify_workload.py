"""Static contract, provenance, fixture, and port-presence checker."""

import json
import math
from pathlib import Path
import struct
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
from parsec_fluidanimate_sph_oracle import (  # noqa: E402
    MAX_OUTPUT_BYTES,
    MAX_PARTICLES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_INPUT_LENGTH,
    expected_output,
)
from parsec_fluidanimate_sph_verifier_oracle import (  # noqa: E402
    expected_output as independent_output,
)

PAPER_URL = "https://www.cs.princeton.edu/techreports/2008/811.pdf"
SOURCE_URL = (
    "https://gem5.googlesource.com/public/gem5-resources/+/refs/heads/develop/"
    "src/parsec/disk-image/parsec/parsec-benchmark/pkgs/apps/fluidanimate/src/serial.cpp"
)
PORTS = (
    "c/f/fluidanimate_sph.c",
    "c3/f/fluidanimate_sph.c3",
    "cpp/f/fluidanimate_sph.cpp",
    "elisa/f/fluidanimate_sph.elisa",
    "mojo/f/fluidanimate_sph.mojo",
    "nim/f/fluidanimate_sph.nim",
    "odin/f/fluidanimate_sph.odin",
    "rust/f/fluidanimate_sph.rs",
    "v/f/fluidanimate_sph.v",
    "zig/f/fluidanimate_sph.zig",
)


def _close_vectors(left: list[float], right: list[float], abs_tol: float,
                   rel_tol: float) -> bool:
    return len(left) == len(right) and all(
        math.isclose(a, b, abs_tol=abs_tol, rel_tol=rel_tol)
        for a, b in zip(left, right)
    )


def _decoded(blob: bytes) -> list[float]:
    if len(blob) % 8:
        raise ValueError("oracle output is not a sequence of binary64 values")
    return list(struct.unpack("<" + "d" * (len(blob) // 8), blob))


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    source = workload.get("source", {})
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "fluidanimate_sph"
            or workload.get("function_symbol") != "fluidanimate_sph"
            or workload.get("abi") != "i64_array_bytes_output"
            or source.get("paper_url") != PAPER_URL
            or source.get("source_file_url") != SOURCE_URL
            or "clean-room" not in source.get("reuse_scope", "")):
        raise ValueError("workload identity or provenance differs from this profile")

    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    workspace = workload.get("workspace", {})
    contract = workload.get("contract", {})
    if (input_spec.get("particle_count_range") != [1, MAX_PARTICLES]
            or input_spec.get("rpm_milli_range") != [500, 5000]
            or input_spec.get("coordinate_milli_range") != [-10000, 10000]
            or input_spec.get("velocity_milli_range") != [-5000, 5000]
            or input_spec.get("maximum_valid_length") != MAX_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_spec.get("invalid_result") != -1
            or input_spec.get("null_input_result") != -1
            or output_spec.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or output_spec.get("maximum_values") != 5 * MAX_PARTICLES
            or output_spec.get("values_per_particle") != 5
            or output_spec.get("invalid_result") != -1
            or output_spec.get("null_output_result") != -2
            or output_spec.get("insufficient_capacity_result") != -2
            or output_spec.get("no_write_on_error") is not True
            or workspace.get("bytes") != 2560
            or "strict squared-distance test r2<h2" not in contract.get("smoothing_length", "")
            or "315/(64*pi*h^9)" not in contract.get("density", "")
            or "viscosity" not in contract.get("pair_acceleration", "")):
        raise ValueError("workload framing or SPH contract differs from the bounded profile")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain named cases")
    required = {
        "isolated-particle-self-density-and-gravity",
        "neighbor-pressure-and-viscosity-pair",
        "coincident-neighbor-distance-guard",
        "support-boundary-excluded",
        "invalid-rpm",
        "malformed-before-output-check",
        "coordinate-out-of-range",
        "short-output-capacity",
        "trailing-word",
        "null-output",
        "null-input",
    }
    seen: set[str] = set()
    abs_tol = output_spec.get("absolute_tolerance", 0.1)
    rel_tol = output_spec.get("relative_tolerance", 1e-10)
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            raise ValueError("case is not a named object")
        case_id = case["id"]
        if case_id in seen:
            raise ValueError(f"duplicate case ID: {case_id}")
        seen.add(case_id)
        values = case.get("input_values", [])
        args = (
            values,
            case.get("output_capacity"),
            case.get("output_is_null", False),
            case.get("input_is_null", False),
            case.get("input_length"),
        )
        primary_result, primary_bytes = expected_output(*args)
        independent_result, independent_bytes = independent_output(*args)
        if case.get("input_length") != len(values):
            raise ValueError(f"input length differs from fixture: {case_id}")
        if primary_result != independent_result or primary_result != case.get("expected_result"):
            raise ValueError(f"case result differs between oracles or fixture: {case_id}")
        primary_values = _decoded(primary_bytes)
        independent_values = _decoded(independent_bytes)
        pinned_values = case.get("expected_output", [])
        if (not _close_vectors(primary_values, independent_values, abs_tol, rel_tol)
                or not _close_vectors(primary_values, pinned_values, abs_tol, rel_tol)):
            raise ValueError(f"case output differs between oracles or fixture: {case_id}")
        if primary_result >= 0 and len(primary_bytes) != primary_result:
            raise ValueError(f"successful byte count differs: {case_id}")
        if primary_result < 0 and (primary_bytes or independent_bytes or pinned_values):
            raise ValueError(f"error case must have no output: {case_id}")
    if not required.issubset(seen):
        raise ValueError(f"workload omits cases: {sorted(required - seen)}")

    generated = workload.get("generated_profile", {})
    if (generated.get("maximum_particles") != MAX_PARTICLES
            or generated.get("maximum_output_bytes") != MAX_OUTPUT_BYTES
            or "deterministic 32-particle" not in generated.get("description", "")):
        raise ValueError("generated maximum-size profile differs from the bounded contract")
    maximum_values = [MAX_PARTICLES, 1695]
    for particle in range(MAX_PARTICLES):
        maximum_values.extend((
            (particle % 8) * 250,
            ((particle // 8) % 2) * 250,
            0,
            (particle % 3) * 250,
            -250 if particle % 2 else 0,
            0,
        ))
    maximum_output = expected_output(maximum_values, MAX_OUTPUT_BYTES)
    maximum_independent = independent_output(maximum_values, MAX_OUTPUT_BYTES)
    if (maximum_output[0] != MAX_OUTPUT_BYTES
            or maximum_output[0] != maximum_independent[0]
            or not _close_vectors(_decoded(maximum_output[1]),
                                  _decoded(maximum_independent[1]), abs_tol, rel_tol)):
        raise ValueError("maximum-size profile differs between direct oracles")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if (PAPER_URL not in readme or SOURCE_URL not in readme
            or "clean-room" not in rights or "No upstream source code" not in rights):
        raise ValueError("README or rights note omits provenance or clean-room scope")
    if len(PORTS) != 10:
        raise ValueError("the checker must enumerate ten ports")
    for relative in PORTS:
        port = ROOT / relative
        if (not port.is_file()
                or "fluidanimate_sph" not in port.read_text(encoding="utf-8")
                or relative not in readme):
            raise ValueError(f"missing port or README entry: {relative}")
    return len(cases)


if __name__ == "__main__":
    print(f"checked {verify_workload()} cases and {len(PORTS)} port paths")
