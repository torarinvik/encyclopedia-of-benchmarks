"""Static metadata and native-path review; no native code is executed."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "gaussian_prime_classifier"
PORTS = {
    "c": "c/g/gaussian_prime_classifier.c",
    "c3": "c3/g/gaussian_prime_classifier.c3",
    "cpp": "cpp/g/gaussian_prime_classifier.cpp",
    "elisa": "elisa/g/gaussian_prime_classifier.elisa",
    "mojo": "mojo/g/gaussian_prime_classifier.mojo",
    "nim": "nim/g/gaussian_prime_classifier.nim",
    "odin": "odin/g/gaussian_prime_classifier.odin",
    "rust": "rust/g/gaussian_prime_classifier.rs",
    "v": "v/g/gaussian_prime_classifier.v",
    "zig": "zig/g/gaussian_prime_classifier.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    package_files = (
        "__init__.py", "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json",
        "workload.json", "primary_oracle.py", "independent_oracle.py",
        "verify_workload.py", "check_inventory.py",
    )
    for name in package_files:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")
    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing native port: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        if SYMBOL not in source:
            issues.append(f"missing exported symbol: {relative}")
        if language == "elisa" and ("UnsafePointer" in source or "view[i64]" not in source):
            issues.append("Elisa port must use a bounded borrowed input view")
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"invalid package JSON: {error}"]
    if (inventory.get("algorithm") != SYMBOL
            or inventory.get("function_symbol") != SYMBOL
            or inventory.get("abi") != "i64_array_scalar"
            or set(inventory.get("native_paths", [])) != set(PORTS.values())):
        issues.append("inventory identity or native port list differs")
    bounds = inventory.get("bounds", {})
    input_meta = workload.get("input", {})
    if (bounds.get("maximum_coordinate_magnitude") != 10000
            or bounds.get("maximum_norm") != 200000000
            or bounds.get("maximum_valid_input_length") != 2
            or bounds.get("maximum_parseable_input_length") != 3
            or bounds.get("workspace_bytes") != 128
            or input_meta.get("maximum_valid_input_length") != 2
            or input_meta.get("maximum_parseable_input_length") != 3
            or input_meta.get("maximum_norm") != 200000000
            or workload.get("workspace", {}).get("bytes") != 128):
        issues.append("inventory/workload bounds differ from the profile")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
