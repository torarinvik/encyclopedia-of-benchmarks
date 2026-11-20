"""Static source and metadata inventory checks for the vEB layout package."""

import json
from pathlib import Path

try:
    from .verify_workload import workload_issues
except ImportError:
    from verify_workload import workload_issues


PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
LANGUAGES = {
    "c": "c",
    "c3": "c3",
    "cpp": "cpp",
    "elisa": "elisa",
    "mojo": "mojo",
    "nim": "nim",
    "odin": "odin",
    "rust": "rs",
    "v": "v",
    "zig": "zig",
}
ALGORITHM = "van_emde_boas_layout_search"


def static_issues() -> list[str]:
    issues = []
    try:
        metadata = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package metadata: {error}"]
    expected_sources = [
        f"{language}/v/{ALGORITHM}.{extension}"
        for language, extension in LANGUAGES.items()
    ]
    listed_sources = metadata.get("sources")
    if metadata.get("algorithm") != ALGORITHM:
        issues.append("inventory algorithm mismatch")
    if metadata.get("function_symbol") != ALGORITHM:
        issues.append("inventory function symbol mismatch")
    if metadata.get("abi") != "i64_array_bytes_output":
        issues.append("inventory ABI mismatch")
    if listed_sources != expected_sources:
        issues.append("inventory source list mismatch")
    for relative in expected_sources:
        if not (ROOT / relative).is_file():
            issues.append(f"missing source: {relative}")
    for relative in metadata.get("artifacts", []):
        if not (ROOT / relative).is_file():
            issues.append(f"missing package artifact: {relative}")
    if workload.get("algorithm") != ALGORITHM or workload.get("abi") != metadata.get("abi"):
        issues.append("workload/inventory identity mismatch")
    if metadata.get("bounds", {}).get("maximum_output_bytes") != 328:
        issues.append("inventory maximum output mismatch")
    if metadata.get("bounds", {}).get("workspace_bytes") != 2048:
        issues.append("inventory workspace mismatch")
    issues.extend(workload_issues())
    return issues


def check_inventory() -> None:
    issues = static_issues()
    if issues:
        raise ValueError("\n".join(issues))


if __name__ == "__main__":
    check_inventory()
