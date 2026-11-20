"""Static fixture, source inventory, and ten-port package checker."""

from __future__ import annotations

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(PACKAGE))
import primary_oracle as primary  # noqa: E402
import independent_oracle as independent  # noqa: E402

TUTORIAL_URL = "https://codeforces.com/blog/entry/140112"
PROPOSAL_URL = "https://github.com/yosupo06/library-checker-problems/issues/1371"
PORTS = {
    "c": ROOT / "c/e/external_point_tangents_convex_polygon.c",
    "c3": ROOT / "c3/e/external_point_tangents_convex_polygon.c3",
    "cpp": ROOT / "cpp/e/external_point_tangents_convex_polygon.cpp",
    "elisa": ROOT / "elisa/e/external_point_tangents_convex_polygon.elisa",
    "mojo": ROOT / "mojo/e/external_point_tangents_convex_polygon.mojo",
    "nim": ROOT / "nim/e/external_point_tangents_convex_polygon.nim",
    "odin": ROOT / "odin/e/external_point_tangents_convex_polygon.odin",
    "rust": ROOT / "rust/e/external_point_tangents_convex_polygon.rs",
    "v": ROOT / "v/e/external_point_tangents_convex_polygon.v",
    "zig": ROOT / "zig/e/external_point_tangents_convex_polygon.zig",
}
NULL_GUARDS = {
    "c": "|| !out",
    "c3": "|| out == null",
    "cpp": "|| !out",
    "elisa": "or output_is_null",
    "mojo": "or output_is_null",
    "nim": "or output.isNil",
    "odin": "|| out == nil",
    "rust": "|| out.is_null()",
    "v": "|| output == nil",
    "zig": "or output_opt == null",
}
LAYER_BUILDERS = {
    "c": "build_layers",
    "c3": "build_layers",
    "cpp": "build_layers",
    "elisa": "ept_build_layers",
    "mojo": "ept_build_layers",
    "nim": "buildLayers",
    "odin": "build_layers",
    "rust": "build_layers",
    "v": "build_layers",
    "zig": "buildLayers",
}
REQUIRED_CASES = {
    "square_four_external_sides",
    "pentagon_bottom_and_top_tangents",
    "sixteen_query_output_capacity",
    "zero_queries_nonnull_zero_capacity",
    "zero_queries_null_output",
    "null_output_with_query",
    "short_output_capacity",
    "collinear_edge_support_line_invalid",
    "boundary_query_invalid",
    "interior_query_invalid_precedes_null_output",
    "duplicate_polygon_vertex_invalid",
    "concave_polygon_invalid",
    "collinear_polygon_vertices_invalid",
    "clockwise_polygon_invalid",
    "trailing_word_invalid_frame",
    "out_of_range_coordinate_invalid",
    "null_input",
}


def verify() -> list[str]:
    errors: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"workload cannot be read: {error}"]

    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != "external_point_tangents_convex_polygon"
            or workload.get("function_symbol") != "external_point_tangents_convex_polygon"
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("oracle") != "benchmarks/e/external_point_tangents_convex_polygon/primary_oracle.py"
            or workload.get("independent_oracle") != "benchmarks/e/external_point_tangents_convex_polygon/independent_oracle.py"):
        errors.append("package identity, ABI, or oracle paths differ from the contract")

    input_contract = workload.get("input", {})
    output_contract = workload.get("output", {})
    if (input_contract.get("vertex_count_range") != [3, primary.MAX_VERTICES]
            or input_contract.get("query_count_range") != [0, primary.MAX_QUERIES]
            or input_contract.get("coordinate_range") != [-primary.MAX_COORDINATE, primary.MAX_COORDINATE]
            or input_contract.get("maximum_valid_length") != primary.MAX_INPUT_LENGTH
            or input_contract.get("maximum_parseable_input_length") != primary.MAX_PARSEABLE_INPUT_LENGTH
            or output_contract.get("maximum_words") != 2 * primary.MAX_QUERIES
            or output_contract.get("maximum_bytes") != primary.MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != primary.WORKSPACE_BYTES):
        errors.append("input, output, or workspace bounds differ from the reviewed contract")

    pinned = workload.get("pinned_sources", [])
    source_urls = {source.get("url") for source in pinned if isinstance(source, dict)}
    if {TUTORIAL_URL, PROPOSAL_URL} - source_urls:
        errors.append("workload omits a pinned primary source")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return errors + ["workload must contain named fixtures"]
    identifiers = {case.get("id") for case in cases if isinstance(case, dict)}
    if len(identifiers) != len(cases) or not REQUIRED_CASES <= identifiers:
        errors.append("fixture IDs are duplicated or required coverage cases are missing")

    for case in cases:
        if not isinstance(case, dict):
            errors.append("fixture entry is not an object")
            continue
        values = case.get("input_values", [])
        expected = (case.get("expected_result"),
                    bytes.fromhex(case.get("expected_output_hex", "")))
        options = {
            "input_is_null": case.get("input_is_null", False),
            "output_is_null": case.get("output_is_null", False),
            "output_capacity": case.get("output_capacity"),
            "input_length": case.get("input_length"),
        }
        if (case.get("input_length") != len(values)
                or primary.expected_output(values, **options) != expected
                or independent.expected_output(values, **options) != expected):
            errors.append(f"fixture/oracle mismatch: {case.get('id')}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if (TUTORIAL_URL not in readme or PROPOSAL_URL not in readme
            or TUTORIAL_URL not in rights or PROPOSAL_URL not in rights
            or "clean-room" not in readme):
        errors.append("README or rights note omits provenance or clean-room status")

    if len(PORTS) != 10:
        errors.append("port inventory must contain all ten languages")
    for language, path in PORTS.items():
        relative = str(path.relative_to(ROOT))
        if not path.is_file():
            errors.append(f"missing {language} port: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if "external_point_tangents_convex_polygon" not in source:
            errors.append(f"{relative} lacks the exported symbol")
        if NULL_GUARDS[language] not in source:
            errors.append(f"{relative} does not reject null output unconditionally")
        if LAYER_BUILDERS[language] not in source:
            errors.append(f"{relative} does not expose one-time chain preprocessing")
        if relative not in readme:
            errors.append(f"README does not link {relative}")

    elisa = PORTS["elisa"].read_text(encoding="utf-8")
    if "UnsafePointer" in elisa or "mutable view[" not in elisa:
        errors.append("Elisa internals should use safe views and fixed arrays")
    return errors


if __name__ == "__main__":
    issues = verify()
    if issues:
        raise SystemExit("\n".join(issues))
    print(f"statically reviewed {len(REQUIRED_CASES)} required fixtures and {len(PORTS)} port paths")
