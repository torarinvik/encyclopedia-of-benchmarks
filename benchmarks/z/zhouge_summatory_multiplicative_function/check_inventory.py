"""Static package checks; does not compile or execute language ports."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/z/zhouge_summatory_multiplicative_function"
ALGORITHM = "zhouge_summatory_multiplicative_function"
LANGUAGE_PATHS = {
    "c": "c/s/zhouge_summatory_multiplicative_function.c",
    "c3": "c3/s/zhouge_summatory_multiplicative_function.c3",
    "cpp": "cpp/s/zhouge_summatory_multiplicative_function.cpp",
    "elisa": "elisa/s/zhouge_summatory_multiplicative_function.elisa",
    "mojo": "mojo/s/zhouge_summatory_multiplicative_function.mojo",
    "nim": "nim/s/zhouge_summatory_multiplicative_function.nim",
    "odin": "odin/s/zhouge_summatory_multiplicative_function.odin",
    "rust": "rust/s/zhouge_summatory_multiplicative_function.rs",
    "v": "v/s/zhouge_summatory_multiplicative_function.v",
    "zig": "zig/s/zhouge_summatory_multiplicative_function.zig",
}
CURSOR_TOKENS = {
    "c": ("g_cursor", "apply_skipped_power_sums"),
    "c3": ("g_cursor", "apply_skipped_power_sums"),
    "cpp": ("g_cursor", "apply_skipped_power_sums"),
    "elisa": ("g_cursor", "zsg_apply_skipped_power_sums"),
    "mojo": ("g_cursor", "apply_skipped_power_sums"),
    "nim": ("gCursor", "applySkippedPowerSums"),
    "odin": ("g_cursor", "apply_skipped_power_sums"),
    "rust": ("g_cursor", "apply_skipped_power_sums"),
    "v": ("g_cursor", "apply_skipped_power_sums"),
    "zig": ("g_cursor", "applySkippedPowerSums"),
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package inventory: {error}"]
    if inventory.get("algorithm") != ALGORITHM or inventory.get("function_symbol") != ALGORITHM:
        issues.append("inventory algorithm or symbol does not match the package")
    if inventory.get("abi") != "i64_array_scalar":
        issues.append("inventory ABI is not i64_array_scalar")
    if inventory.get("workspace_bytes") != 344064:
        issues.append("inventory workspace differs from the documented 344,064-byte cap")
    if inventory.get("languages") != LANGUAGE_PATHS:
        issues.append("inventory must list exactly the ten supported ports")
    for language, relative_path in LANGUAGE_PATHS.items():
        source_path = ROOT / relative_path
        if not source_path.is_file():
            issues.append(f"missing {language} source: {relative_path}")
            continue
        contents = source_path.read_text(encoding="utf-8")
        if any(token not in contents for token in CURSOR_TOKENS[language]):
            issues.append(f"{language} port is missing the deferred-prime g-state correction")
        if "quotients" in contents:
            issues.append(f"{language} port stores a redundant quotient-value array")
    for name in inventory.get("metadata", []):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package metadata: {name}")
    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        for required in (
            "https://oi-wiki.org/math/number-theory/zhou/",
            "yutong.site/wp-content/uploads/2018/09/",
            "341,524",
            "344,064",
            "O(N^(3/4)/log N)",
        ):
            if required not in readme:
                issues.append(f"README is missing required source/contract text: {required}")
    return issues
