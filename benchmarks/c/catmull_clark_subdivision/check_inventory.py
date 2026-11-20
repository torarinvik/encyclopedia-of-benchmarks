"""Static package inventory. This helper must not execute benchmark code."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SYMBOL = "catmull_clark_subdivision"
PORTS = {
    "c": "c/c/catmull_clark_subdivision.c",
    "c3": "c3/c/catmull_clark_subdivision.c3",
    "cpp": "cpp/c/catmull_clark_subdivision.cpp",
    "elisa": "elisa/c/catmull_clark_subdivision.elisa",
    "mojo": "mojo/c/catmull_clark_subdivision.mojo",
    "nim": "nim/c/catmull_clark_subdivision.nim",
    "odin": "odin/c/catmull_clark_subdivision.odin",
    "rust": "rust/c/catmull_clark_subdivision.rs",
    "v": "v/c/catmull_clark_subdivision.v",
    "zig": "zig/c/catmull_clark_subdivision.zig",
}
SOURCE_URLS = (
    "https://doi.org/10.1016/0010-4485(78)90110-0",
    "https://mathworld.wolfram.com/Catmull-ClarkSubdivision.html",
    "https://rosettagit.org/tasks/",
)


def static_issues() -> list[str]:
    issues: list[str] = []
    required = ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                "primary_oracle.py", "independent_oracle.py", "check_inventory.py")
    for filename in required:
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package artifact: {filename}")
    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
        inventory = (PACKAGE / "INVENTORY.md").read_text(encoding="utf-8")
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read static metadata: {error}"]
    for language, relative in PORTS.items():
        port = ROOT / relative
        if not port.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        if SYMBOL not in port.read_text(encoding="utf-8"):
            issues.append(f"export symbol absent from {relative}")
        if relative not in inventory or f"](../../../{relative})" not in readme:
            issues.append(f"inventory or README language link absent: {relative}")
    for url in SOURCE_URLS:
        if url not in readme or url not in rights:
            issues.append(f"source URL missing from README or RIGHTS: {url}")
    for filename in ("primary_oracle.py", "independent_oracle.py"):
        if "expected_output" not in (PACKAGE / filename).read_text(encoding="utf-8"):
            issues.append(f"expected-output function absent from {filename}")
    if workload.get("algorithm") != SYMBOL or workload.get("abi") != "float64_slice_io":
        issues.append("workload algorithm or ABI mismatch")
    if len(workload.get("cases", [])) < 10:
        issues.append("fewer than ten static workload cases")
    return issues


def main() -> None:
    issues = static_issues()
    if issues:
        raise SystemExit("static inventory issues:\n- " + "\n- ".join(issues))
    print(f"{SYMBOL}: package artifacts and {len(PORTS)} ports are present")


if __name__ == "__main__":
    main()
