"""Static inventory and dual-oracle checker for suffix_balanced_tree."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import expected_output as independent_output
    from .primary_oracle import expected_output as primary_output
except ImportError:  # Direct import from this package directory.
    from independent_oracle import expected_output as independent_output
    from primary_oracle import expected_output as primary_output

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "suffix_balanced_tree"
SOURCE_URL = "https://oi-wiki.org/string/suffix-bst/"
PORTS = {
    "c": ROOT / "c/s/suffix_balanced_tree.c",
    "c3": ROOT / "c3/s/suffix_balanced_tree.c3",
    "cpp": ROOT / "cpp/s/suffix_balanced_tree.cpp",
    "elisa": ROOT / "elisa/s/suffix_balanced_tree.elisa",
    "mojo": ROOT / "mojo/s/suffix_balanced_tree.mojo",
    "nim": ROOT / "nim/s/suffix_balanced_tree.nim",
    "odin": ROOT / "odin/s/suffix_balanced_tree.odin",
    "rust": ROOT / "rust/s/suffix_balanced_tree.rs",
    "v": ROOT / "v/s/suffix_balanced_tree.v",
    "zig": ROOT / "zig/s/suffix_balanced_tree.zig",
}


def verify() -> list[str]:
    errors: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"workload cannot be read: {error}"]
    source = workload.get("source", {})
    contract = workload.get("contract", {})
    if (workload.get("schema_version") != 1 or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL or workload.get("abi") != "i64_array_bytes_output"
            or source.get("url") != SOURCE_URL or source.get("license") != "CC BY-SA 4.0 and SATA"):
        errors.append("workload identity or source attribution mismatch")
    if (contract.get("n_range") != [0, 32] or contract.get("symbol_range") != [0, 255]
            or contract.get("tag_limit") != 1 << 62
            or workload.get("input", {}).get("maximum_valid_length") != 33
            or workload.get("output", {}).get("maximum_bytes") != 256):
        errors.append("bounded suffix-tree contract mismatch")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return errors + ["workload must contain named fixtures"]
    identifiers = {case.get("id") for case in cases if isinstance(case, dict)}
    if len(identifiers) != len(cases):
        errors.append("fixture IDs are missing or duplicated")
    for case in cases:
        if not isinstance(case, dict):
            errors.append("fixture entry is not an object")
            continue
        values = case.get("input_values", [])
        input_length = case.get("input_length")
        primary = primary_output(values, case.get("output_capacity"),
                                 case.get("output_is_null", False),
                                 case.get("input_is_null", False), input_length)
        independent = independent_output(values, case.get("output_capacity"),
                                         case.get("output_is_null", False),
                                         case.get("input_is_null", False), input_length)
        if (input_length != len(values) or primary != independent
                or primary[0] != case.get("expected_result")
                or primary[1].hex() != case.get("expected_output_hex")):
            errors.append(f"fixture/oracle mismatch: {case.get('id')}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if SOURCE_URL not in readme or "CC BY-SA 4.0" not in rights or "SATA" not in rights:
        errors.append("README or rights notes omit source attribution")
    if "successor suffixes" not in readme or "midpoint tags" not in readme or "O(N log N)" not in readme:
        errors.append("README omits successor tags, rebuilding, or complexity")
    for language, path in PORTS.items():
        if not path.is_file():
            errors.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            errors.append(f"entrypoint missing from {language} port")
        elif str(path.relative_to(ROOT)) not in readme:
            errors.append(f"README does not link {language} port")
    elisa = PORTS["elisa"].read_text(encoding="utf-8")
    if "UnsafePointer" in elisa or "ptr[" in elisa:
        errors.append("Elisa implementation contains an internal raw pointer")
    return errors


if __name__ == "__main__":
    print("checked static suffix_balanced_tree package")
