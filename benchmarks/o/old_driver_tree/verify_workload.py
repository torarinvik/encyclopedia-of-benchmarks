"""Static inventory and dual-oracle checker for the Old Driver Tree package."""

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
SYMBOL = "old_driver_tree"
SOURCE_URL = "https://en.oi-wiki.org/ds/odt/"
PORTS = {
    "c": ROOT / "c/o/old_driver_tree.c",
    "c3": ROOT / "c3/o/old_driver_tree.c3",
    "cpp": ROOT / "cpp/o/old_driver_tree.cpp",
    "elisa": ROOT / "elisa/o/old_driver_tree.elisa",
    "mojo": ROOT / "mojo/o/old_driver_tree.mojo",
    "nim": ROOT / "nim/o/old_driver_tree.nim",
    "odin": ROOT / "odin/o/old_driver_tree.odin",
    "rust": ROOT / "rust/o/old_driver_tree.rs",
    "v": ROOT / "v/o/old_driver_tree.v",
    "zig": ROOT / "zig/o/old_driver_tree.zig",
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
    if (contract.get("n_range") != [1, 32] or contract.get("operation_count_range") != [0, 32]
            or contract.get("maximum_current_value_magnitude") != 33000
            or contract.get("interval_capacity") != 36
            or workload.get("input", {}).get("maximum_valid_length") != 194
            or workload.get("input", {}).get("maximum_parseable_length") != 195
            or workload.get("output", {}).get("maximum_bytes") != 256):
        errors.append("bounded interval-map contract mismatch")
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
    if "split at `right + 1`, then at `left`" not in readme or "construction-sensitive" not in readme:
        errors.append("README omits interval splitting or complexity caveat")
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
    print("checked static Old Driver Tree package")
