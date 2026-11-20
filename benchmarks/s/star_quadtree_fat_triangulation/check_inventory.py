"""Read-only static package inventory checks for suite integration."""
from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
LANGUAGE_PATHS = (
    "c/s/star_quadtree_fat_triangulation.c",
    "c3/s/star_quadtree_fat_triangulation.c3",
    "cpp/s/star_quadtree_fat_triangulation.cpp",
    "elisa/s/star_quadtree_fat_triangulation.elisa",
    "mojo/s/star_quadtree_fat_triangulation.mojo",
    "nim/s/star_quadtree_fat_triangulation.nim",
    "odin/s/star_quadtree_fat_triangulation.odin",
    "rust/s/star_quadtree_fat_triangulation.rs",
    "v/s/star_quadtree_fat_triangulation.v",
    "zig/s/star_quadtree_fat_triangulation.zig",
)


def static_issues() -> list[str]:
    issues = [f"missing language source: {relative}"
              for relative in LANGUAGE_PATHS if not (ROOT / relative).is_file()]
    for filename in ("README.md", "RIGHTS.md", "INVENTORY.md",
                     "primary_oracle.py", "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package artifact: {filename}")
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read workload metadata: {error}"]
    if workload.get("algorithm") != "star_quadtree_fat_triangulation":
        issues.append("workload algorithm name is inconsistent")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("workload ABI is inconsistent")
    contract = workload.get("contract", {})
    if (contract.get("maximum_input_words") != 24
            or contract.get("maximum_parseable_input_words") != 25
            or contract.get("maximum_output_bytes") != 1032
            or contract.get("workspace_bytes") != 8192):
        issues.append("workload bounds differ from the bounded profile")
    input_metadata = workload.get("input", {})
    if (input_metadata.get("kind") != "signed_64_bit_integer_array"
            or input_metadata.get("maximum_valid_length") != 24
            or input_metadata.get("maximum_parseable_length") != 25):
        issues.append("top-level input metadata differs from the bounded profile")
    output_metadata = workload.get("output", {})
    if (output_metadata.get("kind") != "little_endian_signed_64_bit_word_sequence"
            or output_metadata.get("maximum_output_bytes") != 1032):
        issues.append("top-level output metadata differs from the bounded profile")
    if workload.get("workspace", {}).get("bytes") != 8192:
        issues.append("top-level workspace metadata differs from the bounded profile")
    if len(workload.get("cases", [])) < 5:
        issues.append("workload has too few pinned cases")
    return issues
