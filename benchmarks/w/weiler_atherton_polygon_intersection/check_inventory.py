"""Static package inventory check; authored only, not run."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = {
    "c": "c/w/weiler_atherton_polygon_intersection.c",
    "c3": "c3/w/weiler_atherton_polygon_intersection.c3",
    "cpp": "cpp/w/weiler_atherton_polygon_intersection.cpp",
    "elisa": "elisa/w/weiler_atherton_polygon_intersection.elisa",
    "mojo": "mojo/w/weiler_atherton_polygon_intersection.mojo",
    "nim": "nim/w/weiler_atherton_polygon_intersection.nim",
    "odin": "odin/w/weiler_atherton_polygon_intersection.odin",
    "rust": "rust/w/weiler_atherton_polygon_intersection.rs",
    "v": "v/w/weiler_atherton_polygon_intersection.v",
    "zig": "zig/w/weiler_atherton_polygon_intersection.zig",
}


def verify_static_inventory() -> list[str]:
    issues: list[str] = []
    inventory = json.loads((PACKAGE / "inventory.json").read_text())
    workload = json.loads((PACKAGE / "workload.json").read_text())
    expected_ports = {lang: f"../../../{path}" for lang, path in PORTS.items()}
    if inventory.get("ports") != expected_ports:
        issues.append("inventory port paths differ")
    if inventory.get("abi") != "i64_array_bytes_output":
        issues.append("inventory ABI differs")
    if workload.get("algorithm") != "weiler_atherton_polygon_intersection":
        issues.append("workload algorithm differs")
    if workload.get("input", {}).get("maximum_valid_input_length") != 26:
        issues.append("valid-input bound differs")
    if workload.get("input", {}).get("maximum_parseable_input_length") != 27:
        issues.append("parseable-input bound differs")
    if workload.get("output", {}).get("maximum_output_bytes") != 1680:
        issues.append("output bound differs")
    if workload.get("workspace", {}).get("bytes") != 65536:
        issues.append("workspace bound differs")
    if len(PORTS) != 10:
        issues.append("expected ten language ports")
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} source: {relative}")
        elif "weiler_atherton_polygon_intersection" not in path.read_text():
            issues.append(f"missing symbol in {language} source: {relative}")
    for filename in (
        "README.md", "RIGHTS.md", "INVENTORY.md", "inventory.json",
        "workload.json", "primary_oracle.py", "independent_oracle.py",
        "verify_workload.py",
    ):
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package artifact: {filename}")
    return issues


if __name__ == "__main__":
    errors = verify_static_inventory()
    if errors:
        raise SystemExit("\n".join(errors))
