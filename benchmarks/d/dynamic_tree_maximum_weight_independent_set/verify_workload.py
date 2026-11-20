"""Static inventory and workload checker; it never invokes a language port."""

from __future__ import annotations

import json
from pathlib import Path

from benchmarks.d.dynamic_tree_maximum_weight_independent_set.independent_oracle import (
    expected_output as independent_output,
)
from benchmarks.d.dynamic_tree_maximum_weight_independent_set.primary_oracle import (
    expected_output as primary_output,
)

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "dynamic_tree_maximum_weight_independent_set"
SOURCE_URL = "https://en.oi-wiki.org/dp/dynamic/"
PORTS = {
    "C": ROOT / "c/d/dynamic_tree_maximum_weight_independent_set.c",
    "C3": ROOT / "c3/d/dynamic_tree_maximum_weight_independent_set.c3",
    "C++": ROOT / "cpp/d/dynamic_tree_maximum_weight_independent_set.cpp",
    "Elisa": ROOT / "elisa/d/dynamic_tree_maximum_weight_independent_set.elisa",
    "Mojo": ROOT / "mojo/d/dynamic_tree_maximum_weight_independent_set.mojo",
    "Nim": ROOT / "nim/d/dynamic_tree_maximum_weight_independent_set.nim",
    "Odin": ROOT / "odin/d/dynamic_tree_maximum_weight_independent_set.odin",
    "Rust": ROOT / "rust/d/dynamic_tree_maximum_weight_independent_set.rs",
    "V": ROOT / "v/d/dynamic_tree_maximum_weight_independent_set.v",
    "Zig": ROOT / "zig/d/dynamic_tree_maximum_weight_independent_set.zig",
}
REQUIRED_CASES = {
    "single_vertex_updates", "two_vertex_path", "star_light_child_changes",
    "chain_updates_propagate", "zero_update_count", "cycle_and_disconnected_vertex",
    "negative_initial_weight", "update_vertex_out_of_range", "short_frame",
    "null_output", "short_output_capacity", "null_input",
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
        or source.get("url") != SOURCE_URL
        or source.get("license") != "CC BY-SA 4.0 and SATA"
    ):
        errors.append("workload identity or source attribution mismatch")
    if (
        workload.get("oracle") != "benchmarks/dynamic_tree_maximum_weight_independent_set_oracle.py"
        or workload.get("independent_oracle")
        != "benchmarks/d/dynamic_tree_maximum_weight_independent_set/independent_oracle.py"
    ):
        errors.append("oracle paths mismatch")

    limits = workload.get("input", {})
    output = workload.get("output", {})
    if (
        limits.get("vertex_count_range") != [1, 64]
        or limits.get("update_count_range") != [0, 64]
        or limits.get("weight_range") != [0, 1_000_000]
        or limits.get("maximum_valid_length") != 320
        or limits.get("maximum_parseable_length") != 320
        or output.get("maximum_bytes") != 512
        or workload.get("workspace", {}).get("bytes") != 32768
    ):
        errors.append("bounded input, output, or workspace limits mismatch")

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
        args = (
            values,
            case.get("output_capacity"),
            case.get("output_is_null", False),
            case.get("input_is_null", False),
            case.get("input_length"),
        )
        primary = primary_output(*args)
        independent = independent_output(*args)
        if (
            case.get("input_length") != len(values)
            or primary != independent
            or primary[0] != case.get("expected_result")
            or primary[1].hex() != case.get("expected_output_hex")
        ):
            errors.append(f"fixture/oracle mismatch: {case.get('id')}")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if SOURCE_URL not in readme or "CC BY-SA 4.0" not in rights or "SATA" not in rights:
        errors.append("documentation omits algorithm attribution or rights")
    for language, path in PORTS.items():
        if not path.is_file():
            errors.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            errors.append(f"entrypoint missing from {language} port")
        elif str(path.relative_to(ROOT)) not in readme:
            errors.append(f"README does not link {language} port")
    return errors
