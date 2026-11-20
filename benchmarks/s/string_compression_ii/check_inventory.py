"""Static package inventory; this helper does not run benchmark code."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SYMBOL = "string_compression_ii"
PORTS = {
    "c": "c/s/string_compression_ii.c",
    "c3": "c3/s/string_compression_ii.c3",
    "cpp": "cpp/s/string_compression_ii.cpp",
    "elisa": "elisa/s/string_compression_ii.elisa",
    "mojo": "mojo/s/string_compression_ii.mojo",
    "nim": "nim/s/string_compression_ii.nim",
    "odin": "odin/s/string_compression_ii.odin",
    "rust": "rust/s/string_compression_ii.rs",
    "v": "v/s/string_compression_ii.v",
    "zig": "zig/s/string_compression_ii.zig",
}
SOURCE_URLS = (
    "https://leetcode.com/problems/string-compression-ii/",
    "https://leetcode.com/problems/string-compression/",
)


def static_issues() -> list[str]:
    issues: list[str] = []
    required = (
        "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
        "primary_oracle.py", "independent_oracle.py", "check_inventory.py",
    )
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
            issues.append(f"export symbol missing from {relative}")
        if f"](../../../{relative})" not in readme or relative not in inventory:
            issues.append(f"README or inventory port entry missing: {relative}")
    for url in SOURCE_URLS:
        if url not in readme or url not in rights:
            issues.append(f"source URL missing from README or RIGHTS: {url}")
    for filename in ("primary_oracle.py", "independent_oracle.py"):
        if "expected_result" not in (PACKAGE / filename).read_text(encoding="utf-8"):
            issues.append(f"expected-result function absent from {filename}")
    if workload.get("algorithm") != SYMBOL or workload.get("abi") != "i64_array_scalar":
        issues.append("workload algorithm or ABI mismatch")
    if len(workload.get("cases", [])) < 10:
        issues.append("fewer than ten workload cases")
    return issues


def main() -> None:
    issues = static_issues()
    if issues:
        raise SystemExit("static inventory issues:\n- " + "\n- ".join(issues))
    print(f"{SYMBOL}: package artifacts and {len(PORTS)} ports are present")


if __name__ == "__main__":
    main()
