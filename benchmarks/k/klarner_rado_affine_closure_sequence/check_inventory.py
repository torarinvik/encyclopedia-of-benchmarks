"""Static artifact inventory for the ten A005658 language ports."""

from __future__ import annotations

import json
from pathlib import Path

from .verify_workload import verify_workload

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
EXPECTED_SOURCES = {
    "c": "c/k/klarner_rado_affine_closure_sequence.c",
    "cpp": "cpp/k/klarner_rado_affine_closure_sequence.cpp",
    "rust": "rust/k/klarner_rado_affine_closure_sequence.rs",
    "elisa": "elisa/k/klarner_rado_affine_closure_sequence.elisa",
    "c3": "c3/k/klarner_rado_affine_closure_sequence.c3",
    "nim": "nim/k/klarner_rado_affine_closure_sequence.nim",
    "odin": "odin/k/klarner_rado_affine_closure_sequence.odin",
    "v": "v/k/klarner_rado_affine_closure_sequence.v",
    "zig": "zig/k/klarner_rado_affine_closure_sequence.zig",
    "mojo": "mojo/k/klarner_rado_affine_closure_sequence.mojo",
}
REQUIRED_PACKAGE_FILES = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    "check_inventory.py", "__init__.py",
)


def static_issues() -> list[str]:
    errors: list[str] = verify_workload()
    for language, relative in EXPECTED_SOURCES.items():
        path = ROOT / relative
        if not path.is_file():
            errors.append(f"missing {language} source: {relative}")
        elif "klarner_rado_affine_closure_sequence" not in path.read_text(encoding="utf-8"):
            errors.append(f"source lacks the exported symbol: {relative}")
    for name in REQUIRED_PACKAGE_FILES:
        if not (PACKAGE / name).is_file():
            errors.append(f"missing package artifact: {name}")
    inventory_path = PACKAGE / "INVENTORY.json"
    if inventory_path.is_file():
        inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
        if inventory.get("native_paths") != list(EXPECTED_SOURCES.values()):
            errors.append("machine inventory does not match the ten native paths")
    return errors
