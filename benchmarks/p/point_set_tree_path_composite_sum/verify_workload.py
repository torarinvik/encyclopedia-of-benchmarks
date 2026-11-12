"""Static inventory and dual-oracle checker for the bounded top-tree package."""

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
except ImportError:  # Direct import from this package directory.
    from independent_oracle import expected_output as independent_output

from benchmarks.point_set_tree_path_composite_sum_oracle import (
    expected_output as primary_output,
)

SYMBOL = "point_set_tree_path_composite_sum"
TASK_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/tree/point_set_tree_path_composite_sum/task.md"
PORTS = {
    "C": ROOT / "c/p/point_set_tree_path_composite_sum.c",
    "C3": ROOT / "c3/p/point_set_tree_path_composite_sum.c3",
    "C++": ROOT / "cpp/p/point_set_tree_path_composite_sum.cpp",
    "Elisa": ROOT / "elisa/p/point_set_tree_path_composite_sum.elisa",
    "Mojo": ROOT / "mojo/p/point_set_tree_path_composite_sum.mojo",
    "Nim": ROOT / "nim/p/point_set_tree_path_composite_sum.nim",
    "Odin": ROOT / "odin/p/point_set_tree_path_composite_sum.odin",
    "Rust": ROOT / "rust/p/point_set_tree_path_composite_sum.rs",
    "V": ROOT / "v/p/point_set_tree_path_composite_sum.v",
    "Zig": ROOT / "zig/p/point_set_tree_path_composite_sum.zig",
}
REQUIRED_CASES = {
    "single-vertex-value-updates",
    "two-vertex-reverse-order-and-update-types",
    "star-rake-arbitrary-roots-and-edge-updates",
    "zero-initial-edge-multiplier-invalid",
    "cyclic-and-disconnected-tree-invalid",
    "out-of-range-query-root-invalid",
    "out-of-range-edge-id-invalid",
    "truncated-query-invalid",
    "trailing-word-invalid",
    "short-output-capacity",
    "null-output",
    "null-input",
}


def verify() -> list[str]:
    errors: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"workload cannot be read: {error}"]

    source = workload.get("source", {})
    contract = workload.get("contract", {})
    input_meta = workload.get("input", {})
    output_meta = workload.get("output", {})
    workspace = workload.get("workspace", {})
    if (
        workload.get("schema_version") != 1
        or workload.get("algorithm") != SYMBOL
        or workload.get("function_symbol") != SYMBOL
        or workload.get("abi") != "i64_array_bytes_output"
        or source.get("task_url") != TASK_URL
        or source.get("repository_license") != "Apache-2.0"
    ):
        errors.append("workload identity or source attribution mismatch")
    if (
        workload.get("oracle") != "benchmarks/p/point_set_tree_path_composite_sum/primary_oracle.py"
        or workload.get("independent_oracle")
        != "benchmarks/p/point_set_tree_path_composite_sum/independent_oracle.py"
    ):
        errors.append("oracle paths mismatch")
    if (
        contract.get("n_range") != [1, 16]
        or contract.get("q_range") != [1, 32]
        or contract.get("maximum_cluster_nodes") != 75
        or input_meta.get("maximum_valid_length") != 238
        or input_meta.get("maximum_parseable_length") != 238
        or output_meta.get("maximum_bytes") != 256
        or workspace.get("bytes") != 16384
    ):
        errors.append("bounded tree, frame, output, or workspace limits mismatch")

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
            values,
            case.get("output_capacity"),
            case.get("output_is_null", False),
            case.get("input_is_null", False),
            case.get("input_length"),
        )
        independent = independent_output(
            values,
            case.get("output_capacity"),
            case.get("output_is_null", False),
            case.get("input_is_null", False),
            case.get("input_length"),
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
    if TASK_URL not in readme or "Apache-2.0" not in rights:
        errors.append("documentation omits task attribution or rights")
    for language, path in PORTS.items():
        if not path.is_file():
            errors.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            errors.append(f"entrypoint missing from {language} port")
        elif str(path.relative_to(ROOT)) not in readme:
            errors.append(f"README does not link {language} port")
    elisa = PORTS["Elisa"].read_text(encoding="utf-8") if PORTS["Elisa"].is_file() else ""
    if "UnsafePointer" in elisa or "ptr[" in elisa:
        errors.append("Elisa implementation contains an internal raw pointer")
    return errors


if __name__ == "__main__":
    for error in verify():
        print(error)
