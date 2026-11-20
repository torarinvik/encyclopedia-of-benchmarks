"""Static package inventory; does not run benchmark code."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SYMBOL = "ratcliff_obershelp_similarity"
PORTS = {
    "c": "c/r/ratcliff_obershelp_similarity.c",
    "c3": "c3/r/ratcliff_obershelp_similarity.c3",
    "cpp": "cpp/r/ratcliff_obershelp_similarity.cpp",
    "elisa": "elisa/r/ratcliff_obershelp_similarity.elisa",
    "mojo": "mojo/r/ratcliff_obershelp_similarity.mojo",
    "nim": "nim/r/ratcliff_obershelp_similarity.nim",
    "odin": "odin/r/ratcliff_obershelp_similarity.odin",
    "rust": "rust/r/ratcliff_obershelp_similarity.rs",
    "v": "v/r/ratcliff_obershelp_similarity.v",
    "zig": "zig/r/ratcliff_obershelp_similarity.zig",
}
SOURCES = (
    "https://xlinux.nist.gov/dads/HTML/ratcliffObershelp.html",
    "https://jacobfilipp.com/DrDobbs/articles/DDJ/1988/8807/8807c/8807c.htm",
)


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
    for source in SOURCES:
        if source not in readme or source not in rights or source not in workload.get("source", {}).values():
            issues.append(f"source citation missing from package metadata: {source}")
    if workload.get("algorithm") != SYMBOL or workload.get("abi") != "i64_array_scalar":
        issues.append("workload algorithm or ABI metadata mismatch")
    cases = workload.get("cases", [])
    if len(cases) < 10:
        issues.append("workload has fewer than ten fixtures")
    for case in cases:
        values = case.get("input_values")
        input_length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(input_length) is not int
                or type(is_null) is not bool):
            issues.append(f"fixture has invalid input metadata: {case.get('id')}")
        elif input_length != len(values):
            issues.append(f"fixture buffer/length mismatch: {case.get('id')}")
        elif is_null and input_length != 0:
            issues.append(f"null fixture has nonzero length: {case.get('id')}")
    return issues
