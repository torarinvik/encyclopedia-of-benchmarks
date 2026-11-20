"""Static package path and bound inventory checker; do not run during drafting."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "farey_sequence_ordered_enumeration"


def verify_inventory() -> int:
    inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    if inventory.get("schema_version") != 1 or inventory.get("algorithm") != SYMBOL:
        raise ValueError("inventory identity differs")
    ports = inventory.get("ports")
    if not isinstance(ports, dict) or len(ports) != 10:
        raise ValueError("inventory must list ten language ports")
    for language, relative in ports.items():
        path = ROOT / relative
        if not path.is_file() or SYMBOL not in path.read_text(encoding="utf-8"):
            raise ValueError(f"missing port or symbol: {language}")
        markdown_path = relative.replace(" ", "%20")
        if markdown_path not in readme:
            raise ValueError(f"README link missing for {language}")
    for relative in inventory.get("package_files", []):
        if not (PACKAGE / relative).is_file():
            raise ValueError(f"missing package artifact: {relative}")
    bounds = inventory.get("bounds", {})
    if (
        bounds.get("maximum_order") != 32
        or bounds.get("maximum_valid_input_length") != 1
        or bounds.get("maximum_parseable_input_length") != 2
        or bounds.get("maximum_output_words") != 651
        or bounds.get("maximum_output_bytes") != 5208
        or bounds.get("workspace_bytes") != 0
    ):
        raise ValueError("inventory bounds differ from the package contract")
    return len(ports)


if __name__ == "__main__":
    print(f"statically inventoried {verify_inventory()} ports")
