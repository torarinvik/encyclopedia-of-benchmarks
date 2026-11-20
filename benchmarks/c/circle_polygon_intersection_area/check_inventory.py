"""Static package inventory review; this script does not build or run ports."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
EXPECTED_PORTS = {
    "c": "c/circle_polygon_intersection_area.c",
    "c3": "c3/circle_polygon_intersection_area.c3",
    "cpp": "cpp/circle_polygon_intersection_area.cpp",
    "elisa": "elisa/circle_polygon_intersection_area.elisa",
    "mojo": "mojo/circle_polygon_intersection_area.mojo",
    "nim": "nim/circle_polygon_intersection_area.nim",
    "odin": "odin/circle_polygon_intersection_area.odin",
    "rust": "rust/circle_polygon_intersection_area.rs",
    "v": "v/circle_polygon_intersection_area.v",
    "zig": "zig/circle_polygon_intersection_area.zig",
}


def inventory_errors() -> list[str]:
    errors: list[str] = []
    inventory = json.loads((PACKAGE / "inventory.json").read_text())
    workload = json.loads((PACKAGE / "workload.json").read_text())
    if inventory.get("algorithm") != "circle_polygon_intersection_area":
        errors.append("inventory algorithm name mismatch")
    if inventory.get("abi") != "i64_array_float64":
        errors.append("inventory ABI mismatch")
    if inventory.get("ports") != {
        language: f"../../../{relative}" for language, relative in EXPECTED_PORTS.items()
    }:
        errors.append("inventory port map mismatch")
    if workload.get("algorithm") != "circle_polygon_intersection_area":
        errors.append("workload algorithm name mismatch")
    if workload.get("abi") != "i64_array_float64":
        errors.append("workload ABI mismatch")
    if not workload.get("cases"):
        errors.append("workload has no cases")
    for language, relative in EXPECTED_PORTS.items():
        source = ROOT / relative
        if not source.is_file():
            errors.append(f"missing {language} source: {relative}")
        elif "circle_polygon_intersection_area" not in source.read_text():
            errors.append(f"missing exported symbol in {language}: {relative}")
    for reference in ("primary_oracle.py", "independent_oracle.py", "README.md", "RIGHTS.md"):
        if not (PACKAGE / reference).is_file():
            errors.append(f"missing package reference: {reference}")
    return errors


if __name__ == "__main__":
    problems = inventory_errors()
    if problems:
        raise SystemExit("\n".join(problems))
