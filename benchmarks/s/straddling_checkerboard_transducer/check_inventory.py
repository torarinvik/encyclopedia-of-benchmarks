"""Static source/inventory checker; intentionally not run."""

from __future__ import annotations

import json
from pathlib import Path

from .verify_workload import verify

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "straddling_checkerboard_transducer"
EXPECTED_PORTS = {
    "c": "c/s/straddling_checkerboard_transducer.c",
    "c3": "c3/s/straddling_checkerboard_transducer.c3",
    "cpp": "cpp/s/straddling_checkerboard_transducer.cpp",
    "elisa": "elisa/s/straddling_checkerboard_transducer.elisa",
    "mojo": "mojo/s/straddling_checkerboard_transducer.mojo",
    "nim": "nim/s/straddling_checkerboard_transducer.nim",
    "odin": "odin/s/straddling_checkerboard_transducer.odin",
    "rust": "rust/s/straddling_checkerboard_transducer.rs",
    "v": "v/s/straddling_checkerboard_transducer.v",
    "zig": "zig/s/straddling_checkerboard_transducer.zig",
}
REQUIRED = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    "check_inventory.py", "__init__.py",
)


def static_issues() -> list[str]:
    issues = verify()
    for name in REQUIRED:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read package metadata: {error}"]

    listed = inventory.get("native_paths", [])
    if set(listed) != set(EXPECTED_PORTS.values()) or len(listed) != len(EXPECTED_PORTS):
        issues.append("inventory native port list does not match the ten supported languages")
    if set(inventory.get("languages", [])) != set(EXPECTED_PORTS):
        issues.append("inventory language list does not match the ten supported languages")
    for language, relative in EXPECTED_PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} native port: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if SYMBOL not in source:
            issues.append(f"exported symbol text missing from {relative}")
        if f"](../../../{relative})" not in readme:
            issues.append(f"README native port link missing for {language}")
    elisa_path = ROOT / EXPECTED_PORTS["elisa"]
    if elisa_path.is_file():
        elisa = elisa_path.read_text(encoding="utf-8")
        internal = elisa.split("export fn", 1)[0]
        if "UnsafePointer" in internal or "*i64" in internal:
            issues.append("Elisa helpers must use bounded views; raw pointer belongs at FFI boundary")
        if "input[0:input_length]" not in elisa:
            issues.append("Elisa FFI boundary must form a bounded input view")
    for source_url in (
        "https://www.csd.uoc.gr/~hy458/2022/resources/files/CrypTool-Book-en-v12-May18.pdf",
        "https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks",
    ):
        if source_url not in readme or source_url not in rights:
            issues.append(f"provenance URL missing from README or RIGHTS: {source_url}")
    return issues
