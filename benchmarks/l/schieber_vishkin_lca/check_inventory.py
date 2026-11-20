"""Static package inventory checker; it never launches or compiles language ports."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
ALGORITHM = "schieber_vishkin_lca"
LANGUAGE_PATHS = {
    "c": "c/l/schieber_vishkin_lca.c",
    "c3": "c3/l/schieber_vishkin_lca.c3",
    "cpp": "cpp/l/schieber_vishkin_lca.cpp",
    "elisa": "elisa/l/schieber_vishkin_lca.elisa",
    "mojo": "mojo/l/schieber_vishkin_lca.mojo",
    "nim": "nim/l/schieber_vishkin_lca.nim",
    "odin": "odin/l/schieber_vishkin_lca.odin",
    "rust": "rust/l/schieber_vishkin_lca.rs",
    "v": "v/l/schieber_vishkin_lca.v",
    "zig": "zig/l/schieber_vishkin_lca.zig",
}
REFERENCE_PATHS = (
    "benchmarks/schieber_vishkin_lca_oracle.py",
    "benchmarks/schieber_vishkin_lca_independent_oracle.py",
)


def static_issues() -> list[str]:
    """Report missing or inconsistent source metadata without running algorithms."""
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package metadata: {error}"]

    issues: list[str] = []
    for label, value in (
        ("inventory algorithm", inventory.get("algorithm")),
        ("inventory function symbol", inventory.get("function_symbol")),
        ("workload algorithm", workload.get("algorithm")),
        ("workload function symbol", workload.get("function_symbol")),
    ):
        if value != ALGORITHM:
            issues.append(f"{label} differs")
    if inventory.get("abi") != "i64_array_bytes_output" or workload.get("abi") != "i64_array_bytes_output":
        issues.append("ABI differs")
    if inventory.get("language_sources") != LANGUAGE_PATHS:
        issues.append("language source map differs")

    for relative in LANGUAGE_PATHS.values():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing language source {relative}")
        elif ALGORITHM not in path.read_text(encoding="utf-8"):
            issues.append(f"exported symbol text missing in {relative}")
    for relative in inventory.get("package_files", []):
        if not (PACKAGE / relative).is_file():
            issues.append(f"missing package file {relative}")
    if inventory.get("reference_files") != list(REFERENCE_PATHS):
        issues.append("reference source list differs")
    for relative in REFERENCE_PATHS:
        if not (ROOT / relative).is_file():
            issues.append(f"missing reference source {relative}")

    inventory_source = inventory.get("source", {})
    workload_source = workload.get("source", {})
    if inventory_source.get("title_only_discovery_score") != 21:
        issues.append("title-only score metadata differs")
    for key in ("discovery_index_url", "primary_reference_url", "operational_description_url"):
        if not inventory_source.get(key) or inventory_source.get(key) != workload_source.get(key):
            issues.append(f"source provenance field differs: {key}")
    if inventory_source.get("title") != workload_source.get("title"):
        issues.append("source title differs")

    contract = inventory.get("contract", {})
    workload_input = workload.get("input", {})
    workload_output = workload.get("output", {})
    if contract.get("maximum_valid_input_words") != workload_input.get("maximum_length"):
        issues.append("maximum valid input bound differs")
    if contract.get("maximum_trailing_frame_probe_words") != workload_input.get("maximum_trailing_frame_probe_length"):
        issues.append("maximum trailing-frame probe differs")
    if contract.get("maximum_output_bytes") != workload_output.get("maximum_bytes"):
        issues.append("maximum output bound differs")
    if contract.get("workspace_bytes") != workload.get("workspace", {}).get("logical_scratch_bytes_maximum"):
        issues.append("workspace bound differs")
    return issues


def check_inventory() -> list[str]:
    return static_issues()


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
