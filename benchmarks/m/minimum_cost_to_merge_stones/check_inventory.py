"""Static source/provenance inventory; does not execute benchmark code."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SYMBOL = "minimum_cost_to_merge_stones"
PORTS = {
    "c": "c/m/minimum_cost_to_merge_stones.c",
    "c3": "c3/m/minimum_cost_to_merge_stones.c3",
    "cpp": "cpp/m/minimum_cost_to_merge_stones.cpp",
    "elisa": "elisa/m/minimum_cost_to_merge_stones.elisa",
    "mojo": "mojo/m/minimum_cost_to_merge_stones.mojo",
    "nim": "nim/m/minimum_cost_to_merge_stones.nim",
    "odin": "odin/m/minimum_cost_to_merge_stones.odin",
    "rust": "rust/m/minimum_cost_to_merge_stones.rs",
    "v": "v/m/minimum_cost_to_merge_stones.v",
    "zig": "zig/m/minimum_cost_to_merge_stones.zig",
}
SOURCES = ("https://leetcode.com/problems/minimum-cost-to-merge-stones/",)


def static_issues() -> list[str]:
    issues: list[str] = []
    required = (
        "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
        "primary_oracle.py", "independent_oracle.py", "check_inventory.py",
    )
    for name in required:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    try:
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
        inventory = (PACKAGE / "INVENTORY.md").read_text(encoding="utf-8")
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read static package metadata: {error}"]
    for language, relative in PORTS.items():
        port = ROOT / relative
        if not port.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        if SYMBOL not in port.read_text(encoding="utf-8"):
            issues.append(f"export symbol missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README link missing for {language}")
        if relative not in inventory:
            issues.append(f"inventory entry missing for {language}")
    for url in SOURCES:
        if url not in readme or url not in rights:
            issues.append(f"source URL missing from README or RIGHTS: {url}")
    for name in ("primary_oracle.py", "independent_oracle.py"):
        if "expected_result" not in (PACKAGE / name).read_text(encoding="utf-8"):
            issues.append(f"expected-result reference missing from {name}")
    if workload.get("algorithm") != SYMBOL or workload.get("abi") != "i64_array_scalar":
        issues.append("workload algorithm or ABI metadata mismatch")
    if len(workload.get("cases", [])) < 10:
        issues.append("workload has fewer than ten static cases")
    return issues


def main() -> None:
    issues = static_issues()
    if issues:
        raise SystemExit("static inventory issues:\n- " + "\n- ".join(issues))
    print(f"{SYMBOL}: package artifacts, provenance, and {len(PORTS)} ports are present")


if __name__ == "__main__":
    main()
