"""Static workload, provenance, direct-oracle, and source-path checker."""

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
from water_spatial_oracle import (  # noqa: E402
    MAX_CUTOFF, MAX_GRID_SIDE, MAX_INTERNAL_STORAGE_BYTES, MAX_MOLECULES,
    MAX_OUTPUT_BYTES, MAX_PARSEABLE_INPUT_LENGTH, MAX_VALID_INPUT_LENGTH,
    MAX_WORKSPACE_BYTES, expected_output,
)
from water_spatial_verifier_oracle import (  # noqa: E402
    expected_output as independent_output,
)

PAPER_URL = "https://pages.cs.wisc.edu/~markhill/restricted/isca95_splash2.pdf"
SOURCE_URL = "https://github.com/staceyson/splash2"
PORTS = (
    "c/w/water_spatial.c",
    "c3/w/water_spatial.c3",
    "cpp/w/water_spatial.cpp",
    "elisa/w/water_spatial.elisa",
    "mojo/w/water_spatial.mojo",
    "nim/w/water_spatial.nim",
    "odin/w/water_spatial.odin",
    "rust/w/water_spatial.rs",
    "v/w/water_spatial.v",
    "zig/w/water_spatial.zig",
)


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    source = workload.get("source", {})
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "water_spatial"
            or workload.get("function_symbol") != "water_spatial"
            or workload.get("abi") != "i64_array_bytes_output"
            or source.get("paper_url") != PAPER_URL
            or source.get("source_mirror") != SOURCE_URL):
        raise ValueError("workload identity or provenance differs from the reviewed profile")
    if (workload.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != MAX_WORKSPACE_BYTES
            or workload.get("internal_workspace", {}).get("bytes") != MAX_INTERNAL_STORAGE_BYTES):
        raise ValueError("workload framing differs from the bounded profile")
    contract = workload.get("contract", {})
    if (contract.get("molecule_count_range") != [0, MAX_MOLECULES]
            or contract.get("grid_side_range") != [1, MAX_GRID_SIDE]
            or contract.get("cutoff_range") != [1, MAX_CUTOFF]
            or "nonperiodic" not in contract.get("coordinate_range", "")
            or "26 adjacent cells" not in contract.get("cell_rule", "")
            or "truncation toward zero" not in contract.get("fixed_point_rule", "")):
        raise ValueError("workload mathematical bounds differ from the documented contract")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain named cases")
    required = {
        "empty-domain", "single-molecule-no-self-pair", "pair-across-cell-boundary",
        "sixteen-molecule-regular-cell-grid",
        "strict-cutoff-boundary-excluded", "negative-fractional-pair-truncation",
        "zero-charge-pair-counted", "invalid-grid-side", "coordinate-at-box-end",
        "charge-out-of-range", "truncated-frame", "extra-word-frame",
        "malformed-before-capacity", "short-output-capacity", "null-output", "null-input",
    }
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            raise ValueError("case is not a named object")
        if case["id"] in seen:
            raise ValueError(f"duplicate case ID: {case['id']}")
        seen.add(case["id"])
        values = case.get("input_values", [])
        args = (values, case.get("output_capacity"), case.get("output_is_null", False),
                case.get("input_is_null", False), case.get("input_length"))
        primary = expected_output(*args)
        independent = independent_output(*args)
        if (case.get("input_length") != len(values)
                or primary != independent
                or primary[0] != case.get("expected_result")):
            raise ValueError(f"case differs between direct oracles: {case['id']}")
        if ("expected_output_hex" in case
                and primary[1].hex() != case["expected_output_hex"].lower()):
            raise ValueError(f"pinned output differs from both direct oracles: {case['id']}")
        if primary[0] >= 0 and len(primary[1]) != primary[0]:
            raise ValueError(f"successful result byte count differs: {case['id']}")
        if primary[0] < 0 and primary[1]:
            raise ValueError(f"error case contains output bytes: {case['id']}")
    if not required.issubset(seen):
        raise ValueError(f"workload omits cases: {sorted(required - seen)}")

    generated = workload.get("generated_profile", {})
    if (generated.get("maximum_n") != MAX_MOLECULES
            or generated.get("maximum_output_bytes") != MAX_OUTPUT_BYTES
            or "deterministic 4x4x4 lattice" not in generated.get("dense_case_description", "")
            or "separated cell regions" not in generated.get("sparse_case_description", "")):
        raise ValueError("generated workload description differs from bounded profile")

    # A deterministic maximum-size profile checks the fixed storage and frame bounds.
    lattice = []
    for index in range(MAX_MOLECULES):
        lattice.extend((index % 4, (index // 4) % 4, index // 16,
                        1 if index % 2 == 0 else -1))
    max_values = [MAX_MOLECULES, 4, 2, *lattice]
    max_output = expected_output(max_values, MAX_OUTPUT_BYTES)
    max_independent = independent_output(max_values, MAX_OUTPUT_BYTES)
    if max_output != max_independent or max_output[0] != MAX_OUTPUT_BYTES:
        raise ValueError("maximum-size generated profile differs between direct oracles")
    sparse_particles = []
    for index in range(MAX_MOLECULES):
        sparse_particles.extend((2 * (index % 4), 2 * ((index // 4) % 4),
                                 2 * (index // 16),
                                 1 if index % 2 == 0 else -1))
    sparse_values = [MAX_MOLECULES, 8, 1, *sparse_particles]
    sparse_output = expected_output(sparse_values, MAX_OUTPUT_BYTES)
    sparse_independent = independent_output(sparse_values, MAX_OUTPUT_BYTES)
    if (sparse_output != sparse_independent or sparse_output[0] != MAX_OUTPUT_BYTES
            or int.from_bytes(sparse_output[1][-8:], "little", signed=True) != 0):
        raise ValueError("sparse generated profile differs between direct oracles")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if PAPER_URL not in readme or SOURCE_URL not in readme or "No upstream source" not in rights:
        raise ValueError("README or rights note omits provenance or clean-room scope")
    if len(PORTS) != 10:
        raise ValueError("the checker must enumerate ten ports")
    for relative in PORTS:
        port = ROOT / relative
        if (not port.is_file()
                or "water_spatial" not in port.read_text(encoding="utf-8")
                or relative not in readme):
            raise ValueError(f"missing port or README entry: {relative}")
    return len(cases)


if __name__ == "__main__":
    print(f"checked {verify_workload()} cases and {len(PORTS)} port paths")
