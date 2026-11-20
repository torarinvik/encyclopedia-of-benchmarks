"""Static source-path, provenance, and workload inventory review."""

from __future__ import annotations

import json
from pathlib import Path

from .verify_workload import verify_workload

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
PORTS = {
    "c": "c/b/bdd_symbolic_reachability.c",
    "cpp": "cpp/b/bdd_symbolic_reachability.cpp",
    "rust": "rust/b/bdd_symbolic_reachability.rs",
    "elisa": "elisa/b/bdd_symbolic_reachability.elisa",
    "c3": "c3/b/bdd_symbolic_reachability.c3",
    "nim": "nim/b/bdd_symbolic_reachability.nim",
    "odin": "odin/b/bdd_symbolic_reachability.odin",
    "v": "v/b/bdd_symbolic_reachability.v",
    "zig": "zig/b/bdd_symbolic_reachability.zig",
    "mojo": "mojo/b/bdd_symbolic_reachability.mojo",
}
PACKAGE_FILES = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    "check_inventory.py", "__init__.py",
)


def static_issues() -> list[str]:
    errors = verify_workload()
    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
        metadata = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return errors + [f"cannot read package documentation or inventory: {error}"]

    if not isinstance(metadata, dict):
        return errors + ["inventory metadata must be an object"]
    if metadata.get("algorithm") != "bdd_symbolic_reachability":
        errors.append("inventory algorithm identity differs")
    if metadata.get("native_paths") != list(PORTS.values()):
        errors.append("inventory native paths differ from the ten-port map")
    bounds = metadata.get("bounds")
    expected_bounds = {
        "maximum_valid_input_length": 132,
        "maximum_parseable_input_length": 133,
        "maximum_output": 511,
        "workspace_bytes": 294_912,
        "fixed_array_bytes_max": 218_536,
        "fixed_array_bytes_without_transform_results": 150_536,
        "node_capacity": 17_000,
        "conservative_per_round_node_bound": 16_531,
        "unique_table_capacity": 32_768,
        "binary_apply_memoized": False,
    }
    if (not isinstance(bounds, dict)
            or any(bounds.get(key) != value for key, value in expected_bounds.items())):
        errors.append("inventory workspace or input-bound accounting differs")
    for accounting in ("16,531", "218,536", "150,536", "288 KiB"):
        if accounting not in readme:
            errors.append(f"README workspace accounting is missing {accounting}")
    for name in PACKAGE_FILES:
        if not (PACKAGE / name).is_file():
            errors.append(f"missing package artifact: {name}")
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            errors.append(f"missing {language} port: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if "bdd_symbolic_reachability" not in source:
            errors.append(f"exported symbol text missing from {relative}")
        normalized = source.replace("_", "").lower()
        if "maxnodes" not in normalized or "17000" not in normalized:
            errors.append(f"node capacity differs from the reviewed bound in {relative}")
        if "uniquecap" not in normalized or "32768" not in normalized:
            errors.append(f"unique-table capacity differs from the reviewed bound in {relative}")
        if f"](../../../{relative})" not in readme:
            errors.append(f"README link mismatch for {language}")
    for url in (
        "https://doi.org/10.1007/978-1-4939-2864-4_416",
        "https://doi.org/10.1007/978-1-4939-2864-4_48",
    ):
        if url not in readme or url not in rights:
            errors.append(f"source URL missing from README or RIGHTS: {url}")
    elisa_path = ROOT / PORTS["elisa"]
    if elisa_path.is_file():
        elisa = elisa_path.read_text(encoding="utf-8")
        if "UnsafePointer" in elisa or "*i64" in elisa:
            errors.append("Elisa should keep raw pointer use at the exported FFI boundary")
    return errors
