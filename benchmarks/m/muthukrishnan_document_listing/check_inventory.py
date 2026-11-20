"""Static metadata/path inventory; intentionally not executed."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
LANGUAGE_PATHS = {
    "C": "c/m/muthukrishnan_document_listing.c",
    "C3": "c3/m/muthukrishnan_document_listing.c3",
    "C++": "cpp/m/muthukrishnan_document_listing.cpp",
    "Elisa": "elisa/m/muthukrishnan_document_listing.elisa",
    "Mojo": "mojo/m/muthukrishnan_document_listing.mojo",
    "Nim": "nim/m/muthukrishnan_document_listing.nim",
    "Odin": "odin/m/muthukrishnan_document_listing.odin",
    "Rust": "rust/m/muthukrishnan_document_listing.rs",
    "V": "v/m/muthukrishnan_document_listing.v",
    "Zig": "zig/m/muthukrishnan_document_listing.zig",
}
PACKAGE_FILES = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json", "workload.json",
    "primary_oracle.py", "independent_oracle.py", "verify_workload.py",
    "check_inventory.py", "__init__.py",
)


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        metadata = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"invalid package metadata: {error}"]
    if metadata.get("algorithm") != "muthukrishnan_document_listing":
        issues.append("inventory algorithm differs")
    if metadata.get("abi") != "i64_array_bytes_output":
        issues.append("inventory ABI differs")
    if metadata.get("language_sources") != LANGUAGE_PATHS:
        issues.append("inventory language map differs")
    if metadata.get("output_order") != \
            "Within each query, IDs are ordered by increasing suffix-array rank of their first occurrence; the primary sorts RMQ witnesses and the independent reference scans left to right.":
        issues.append("inventory output order differs from the contract")
    if metadata.get("complexity") != {
            "primary": "O(N log N + QD log D), including witness-rank sorting",
            "independent_reference": "O(QN), direct interval scan",
    }:
        issues.append("inventory complexity differs from the contract")
    for language, relative in LANGUAGE_PATHS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} port: {relative}")
            continue
        if "muthukrishnan_document_listing" not in path.read_text(encoding="utf-8"):
            issues.append(f"{language} source is missing the exported symbol")
    for relative in PACKAGE_FILES:
        if not (PACKAGE / relative).is_file():
            issues.append(f"missing package artifact: {relative}")
    if workload.get("maximum_valid_input_length") not in (None, 67):
        issues.append("unexpected maximum valid input length")
    if workload.get("maximum_output_bytes") not in (None, 144):
        issues.append("unexpected maximum output size")
    if workload.get("input", {}).get("maximum_valid_length") != 67 or \
            workload.get("input", {}).get("maximum_parseable_length") != 68 or \
            workload.get("output", {}).get("kind") != \
                "packed byte records in increasing first-occurrence rank order" or \
            workload.get("output", {}).get("maximum_bytes") != 144 or \
            "increasing first-occurrence suffix-array rank" not in workload.get("output", {}).get("encoding", "") or \
            "recursion preorder" in workload.get("output", {}).get("encoding", "") or \
            workload.get("contract", {}).get("time_complexity") != \
                "Primary O(N log N + QD log D), including sorting each query's at most D RMQ witnesses by suffix rank; independent direct interval scan O(QN)." or \
            workload.get("workspace", {}).get("bytes") != 4096:
        issues.append("workload resource metadata differs from contract")
    if metadata.get("language_sources") != LANGUAGE_PATHS:
        return issues
    for relative in metadata.get("package_files", []):
        if not (PACKAGE / relative).is_file():
            issues.append(f"inventory names missing package artifact: {relative}")
    return issues


def check_inventory() -> list[str]:
    return static_issues()


if __name__ == "__main__":
    raise SystemExit("\n".join(static_issues()))
