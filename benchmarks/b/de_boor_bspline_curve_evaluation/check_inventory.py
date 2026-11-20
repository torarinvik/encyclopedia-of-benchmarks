"""Static package inventory API; intentionally not run here."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
PORTS = (
    "c/b/de_boor_bspline_curve_evaluation.c",
    "c3/b/de_boor_bspline_curve_evaluation.c3",
    "cpp/b/de_boor_bspline_curve_evaluation.cpp",
    "elisa/b/de_boor_bspline_curve_evaluation.elisa",
    "mojo/b/de_boor_bspline_curve_evaluation.mojo",
    "nim/b/de_boor_bspline_curve_evaluation.nim",
    "odin/b/de_boor_bspline_curve_evaluation.odin",
    "rust/b/de_boor_bspline_curve_evaluation.rs",
    "v/b/de_boor_bspline_curve_evaluation.v",
    "zig/b/de_boor_bspline_curve_evaluation.zig",
)
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json", "__init__.py",
    "workload.json", "primary_oracle.py", "independent_oracle.py",
    "verify_workload.py", "check_inventory.py",
)


def static_issues() -> list[str]:
    issues: list[str] = []
    for name in REQUIRED:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read package metadata: {error}"]
    if inventory.get("algorithm") != "de_boor_bspline_curve_evaluation":
        issues.append("inventory algorithm identity differs")
    if inventory.get("abi") != "float64_slice_io":
        issues.append("inventory ABI differs")
    if inventory.get("ports") != list(PORTS):
        issues.append("inventory source paths differ")
    if (inventory.get("workspace", {}).get("elements") != 1
            or inventory.get("workspace", {}).get("bytes") != 128):
        issues.append("inventory workspace differs")
    for relative in PORTS:
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing port: {relative}")
        elif "de_boor_bspline_curve_evaluation" not in path.read_text(encoding="utf-8"):
            issues.append(f"export symbol missing: {relative}")
        if relative.rsplit("/", 1)[-1] not in readme:
            issues.append(f"README omits port filename: {relative}")
    elisa_path = ROOT / "elisa/b/de_boor_bspline_curve_evaluation.elisa"
    if elisa_path.is_file():
        source = elisa_path.read_text(encoding="utf-8")
        if "view[f64]" not in source or "UnsafePointer" in source or "*f64" in source:
            issues.append("Elisa should use bounded views internally and borrowed ABI references")
    return issues


def check_inventory() -> list[str]:
    return static_issues()


if __name__ == "__main__":
    problems = check_inventory()
    if problems:
        raise SystemExit("\n".join(problems))
