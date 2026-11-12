"""Static workload, oracle, provenance, and ten-port inventory checker."""

from __future__ import annotations

import json
import sys
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

try:
    from .independent_oracle import expected_output as independent_output
except ImportError:  # Direct invocation from this package directory.
    from independent_oracle import expected_output as independent_output

from benchmarks.dynamic_top_tree_component_diameter_oracle import (
    expected_output as primary_output,
)

SYMBOL = "dynamic_top_tree_component_diameter"
TASK_URL = "https://oi-wiki.org/ds/top-tree/"
PORTS = {
    "C": ROOT / "c/d/dynamic_top_tree_component_diameter.c",
    "C3": ROOT / "c3/d/dynamic_top_tree_component_diameter.c3",
    "C++": ROOT / "cpp/d/dynamic_top_tree_component_diameter.cpp",
    "Elisa": ROOT / "elisa/d/dynamic_top_tree_component_diameter.elisa",
    "Mojo": ROOT / "mojo/d/dynamic_top_tree_component_diameter.mojo",
    "Nim": ROOT / "nim/d/dynamic_top_tree_component_diameter.nim",
    "Odin": ROOT / "odin/d/dynamic_top_tree_component_diameter.odin",
    "Rust": ROOT / "rust/d/dynamic_top_tree_component_diameter.rs",
    "V": ROOT / "v/d/dynamic_top_tree_component_diameter.v",
    "Zig": ROOT / "zig/d/dynamic_top_tree_component_diameter.zig",
}
REQUIRED_CASES = {
    "path-edge-updates", "star-rake-summary-updates", "six-vertex-path-compress-summary",
    "single-vertex-zero-diameter", "cyclic-initial-edge-list", "initial-weight-over-limit",
    "update-edge-id-out-of-range", "query-reserved-fields-nonzero", "unknown-operation",
    "short-frame", "null-output", "short-output-capacity", "null-input",
}


def verify() -> list[str]:
    errors: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"workload cannot be read: {error}"]

    source = workload.get("source", {})
    if (
        workload.get("schema_version") != 1
        or workload.get("algorithm") != SYMBOL
        or workload.get("function_symbol") != SYMBOL
        or workload.get("abi") != "i64_array_bytes_output"
        or source.get("url") != TASK_URL
        or source.get("license") != "CC BY-SA 4.0 and SATA"
    ):
        errors.append("workload identity or source attribution mismatch")
    if (
        workload.get("oracle") != "benchmarks/dynamic_top_tree_component_diameter_oracle.py"
        or workload.get("independent_oracle")
        != "benchmarks/d/dynamic_top_tree_component_diameter/independent_oracle.py"
    ):
        errors.append("oracle paths mismatch")

    limits = workload.get("input", {})
    output = workload.get("output", {})
    workspace = workload.get("workspace", {})
    contract = workload.get("contract", {})
    if (
        limits.get("vertex_count_range") != [1, 16]
        or limits.get("operation_count_range") != [0, 32]
        or limits.get("maximum_valid_length") != 143
        or limits.get("maximum_parseable_length") != 143
        or output.get("maximum_bytes") != 256
        or workspace.get("bytes") != 16384
        or contract.get("maximum_cluster_nodes") != 75
        or contract.get("maximum_weighted_diameter") != 15000
    ):
        errors.append("bounded input, output, workspace, or summary limits mismatch")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return errors + ["workload must contain named cases"]
    ids = [case.get("id") for case in cases if isinstance(case, dict)]
    if len(ids) != len(cases) or len(set(ids)) != len(ids) or not REQUIRED_CASES <= set(ids):
        errors.append("fixture IDs are missing, duplicated, or malformed")
    for case in cases:
        if not isinstance(case, dict):
            errors.append("fixture entry is not an object")
            continue
        values = case.get("input_values", [])
        primary = primary_output(
            values, case.get("output_capacity"), case.get("output_is_null", False),
            case.get("input_is_null", False), case.get("input_length"),
        )
        independent = independent_output(
            values, case.get("output_capacity"), case.get("output_is_null", False),
            case.get("input_is_null", False), case.get("input_length"),
        )
        if (
            case.get("input_length") != len(values)
            or primary != independent
            or primary[0] != case.get("expected_result")
            or primary[1].hex() != case.get("expected_output_hex")
        ):
            errors.append(f"fixture/oracle mismatch: {case.get('id')}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if TASK_URL not in readme or "CC BY-SA 4.0" not in rights or "SATA" not in rights:
        errors.append("documentation omits algorithm attribution or rights")
    for language, path in PORTS.items():
        if not path.is_file():
            errors.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            errors.append(f"entrypoint missing from {language} port")
        elif str(path.relative_to(ROOT)) not in readme:
            errors.append(f"README does not link {language} port")
    return errors


if __name__ == "__main__":
    for error in verify():
        print(error)
