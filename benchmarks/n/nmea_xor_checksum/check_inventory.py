"""Static artifact-presence check; does not compile or execute language ports."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
STEM = "nmea_xor_checksum"
PORTS = {
    "C": "c/n/nmea_xor_checksum.c",
    "C3": "c3/n/nmea_xor_checksum.c3",
    "C++": "cpp/n/nmea_xor_checksum.cpp",
    "Elisa": "elisa/n/nmea_xor_checksum.elisa",
    "Mojo": "mojo/n/nmea_xor_checksum.mojo",
    "Nim": "nim/n/nmea_xor_checksum.nim",
    "Odin": "odin/n/nmea_xor_checksum.odin",
    "Rust": "rust/n/nmea_xor_checksum.rs",
    "V": "v/n/nmea_xor_checksum.v",
    "Zig": "zig/n/nmea_xor_checksum.zig",
}
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    "check_inventory.py",
)
METHOD_URL = "https://gpsd.gitlab.io/gpsd/NMEA.html"


def static_issues() -> list[str]:
    issues = [f"missing package artifact: {name}" for name in REQUIRED
              if not (PACKAGE / name).is_file()]
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
        inventory = (PACKAGE / "INVENTORY.md").read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read package metadata: {error}"]
    if workload.get("algorithm") != STEM or workload.get("function_symbol") != STEM:
        issues.append("workload identity differs from the exported symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("workload ABI is not i64_array_scalar")
    for text, label in ((readme, "README"), (rights, "rights note"),
                        (inventory, "inventory")):
        if METHOD_URL not in text:
            issues.append(f"protocol source missing from {label}")
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        try:
            source = path.read_text(encoding="utf-8")
        except OSError as error:
            issues.append(f"cannot read {relative}: {error}")
            continue
        if STEM not in source:
            issues.append(f"export symbol missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README source link mismatch for {relative}")
    elisa = (ROOT / PORTS["Elisa"]).read_text(encoding="utf-8")
    if "UnsafePointer" in elisa or "*i64" in elisa:
        issues.append("Elisa port should keep its borrowed input reference")
    return issues
