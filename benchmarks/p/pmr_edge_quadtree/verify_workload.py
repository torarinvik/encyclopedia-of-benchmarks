"""Static metadata and source inventory checks for the PMR package."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "pmr_edge_quadtree"
DOI_URL = "https://doi.org/10.1007/978-1-4939-2864-4_585"
PORTS = {
    "C": ROOT / "c/p/pmr_edge_quadtree.c",
    "C3": ROOT / "c3/p/pmr_edge_quadtree.c3",
    "C++": ROOT / "cpp/p/pmr_edge_quadtree.cpp",
    "Elisa": ROOT / "elisa/p/pmr_edge_quadtree.elisa",
    "Mojo": ROOT / "mojo/p/pmr_edge_quadtree.mojo",
    "Nim": ROOT / "nim/p/pmr_edge_quadtree.nim",
    "Odin": ROOT / "odin/p/pmr_edge_quadtree.odin",
    "Rust": ROOT / "rust/p/pmr_edge_quadtree.rs",
    "V": ROOT / "v/p/pmr_edge_quadtree.v",
    "Zig": ROOT / "zig/p/pmr_edge_quadtree.zig",
}


def verify() -> list[str]:
    errors: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"workload cannot be read: {error}"]

    source = workload.get("pinned_source", {})
    if (workload.get("schema_version") != 1 or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"
            or source.get("chapter") != 585
            or source.get("doi") != "10.1007/978-1-4939-2864-4_585"
            or source.get("url") != DOI_URL or source.get("section") != "PM quadtrees"):
        errors.append("workload identity or chapter attribution mismatch")

    contract = workload.get("contract", {})
    if (contract.get("segment_count_range") != [0, 8]
            or contract.get("threshold_range") != [1, 8]
            or contract.get("endpoint_coordinate_range") != [0, 255]
            or contract.get("root_square") != "[-0.5,255.5] x [-0.5,255.5]; cell bounds are represented in doubled integer coordinates."
            or contract.get("depth_limit") != 8 or contract.get("node_limit") != 2048
            or contract.get("maximum_valid_input_length") != 34
            or contract.get("maximum_parseable_input_length") != 35
            or contract.get("maximum_output_words") != 24578
            or contract.get("maximum_output_bytes") != 196624):
        errors.append("bounded PMR input, tree, or output contract mismatch")

    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    workspace = workload.get("workspace", {})
    if (input_spec.get("maximum_valid_length") != 34
            or input_spec.get("maximum_parseable_length") != 35
            or input_spec.get("null_input_result") != -1
            or output_spec.get("maximum_words") != 24578
            or output_spec.get("maximum_bytes") != 196624
            or output_spec.get("null_output_result") != -2
            or output_spec.get("insufficient_capacity_result") != -2
            or output_spec.get("no_write_on_error") is not True
            or workspace.get("bytes") != 393216):
        errors.append("input/output ABI or workspace metadata mismatch")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return errors + ["workload must contain named fixture cases"]
    identifiers = [case.get("id") for case in cases if isinstance(case, dict)]
    if len(identifiers) != len(cases) or len(set(identifiers)) != len(cases):
        errors.append("fixture IDs are missing or duplicated")
    by_id = {case.get("id"): case for case in cases if isinstance(case, dict)}
    required = {"empty-root-leaf", "single-segment-root-leaf", "split-boundary-redistribution",
                "degenerate-segment", "bounded-duplicate-segment-overflow",
                "coordinate-out-of-range", "invalid-threshold",
                "trailing-word", "null-output", "short-output", "null-input"}
    if not required.issubset(by_id):
        errors.append("required valid, invalid, and output-boundary fixtures are missing")
    for case in cases:
        if not isinstance(case, dict):
            continue
        values = case.get("input_values")
        if not isinstance(values, list) or any(type(value) is not int for value in values):
            errors.append(f"fixture input is malformed: {case.get('id')}")
        expected = case.get("expected_result")
        encoded = case.get("expected_output_hex")
        if not isinstance(expected, int):
            errors.append(f"fixture result is missing: {case.get('id')}")
        elif expected >= 0:
            if not isinstance(encoded, str):
                errors.append(f"successful fixture lacks expected bytes: {case.get('id')}")
            else:
                try:
                    raw = bytes.fromhex(encoded)
                except ValueError:
                    errors.append(f"fixture output is not hexadecimal: {case.get('id')}")
                else:
                    if len(raw) != expected or expected % 8 != 0:
                        errors.append(f"fixture output length is inconsistent: {case.get('id')}")
        elif encoded is not None:
            errors.append(f"error fixture must not declare output bytes: {case.get('id')}")

    profile = next((item for item in workload.get("measurement", {}).get("profiles", [])
                    if isinstance(item, dict) and item.get("id") == "split-boundary-redistribution"), None)
    split_case = by_id.get("split-boundary-redistribution")
    if (profile is None or split_case is None
            or profile.get("input_values") != split_case.get("input_values")
            or profile.get("expected_result") != split_case.get("expected_result")
            or profile.get("expected_output_hex") != split_case.get("expected_output_hex")):
        errors.append("measured split-boundary profile differs from its named fixture")

    for reference in ("primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / reference).is_file():
            errors.append(f"missing reference implementation: {reference}")
    readme_path = PACKAGE / "README.md"
    rights_path = PACKAGE / "RIGHTS.md"
    inventory_path = PACKAGE / "INVENTORY.md"
    if not readme_path.is_file() or not rights_path.is_file() or not inventory_path.is_file():
        errors.append("README, rights, or source inventory is missing")
    else:
        readme = readme_path.read_text(encoding="utf-8")
        rights = rights_path.read_text(encoding="utf-8")
        inventory = inventory_path.read_text(encoding="utf-8")
        for text, label in ((readme, "README"), (rights, "rights")):
            if DOI_URL not in text or "clean-room" not in text.lower():
                errors.append(f"{label} omits DOI attribution or clean-room provenance")
        for language, path in PORTS.items():
            relative = str(path.relative_to(ROOT))
            if not path.is_file():
                errors.append(f"missing {language} port: {relative}")
                continue
            source_text = path.read_text(encoding="utf-8")
            if SYMBOL not in source_text:
                errors.append(f"entrypoint missing from {language} port")
            if relative not in inventory or relative not in readme:
                errors.append(f"README or inventory omits {language} port")
    return errors


if __name__ == "__main__":
    print("checked static PMR edge quadtree package metadata")
