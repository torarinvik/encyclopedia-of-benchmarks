"""Static inventory metadata for the bounded CL benchmark; not run at authoring."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
REPO_ROOT = PACKAGE.parents[2]
ALGORITHM = "random_3sat_cl_bucket_heuristic"
LANGUAGE_FILES = {
    "c": f"c/r/{ALGORITHM}.c",
    "c3": f"c3/r/{ALGORITHM}.c3",
    "cpp": f"cpp/r/{ALGORITHM}.cpp",
    "elisa": f"elisa/r/{ALGORITHM}.elisa",
    "mojo": f"mojo/r/{ALGORITHM}.mojo",
    "nim": f"nim/r/{ALGORITHM}.nim",
    "odin": f"odin/r/{ALGORITHM}.odin",
    "rust": f"rust/r/{ALGORITHM}.rs",
    "v": f"v/r/{ALGORITHM}.v",
    "zig": f"zig/r/{ALGORITHM}.zig",
}
PACKAGE_FILES = (
    "README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
    "inventory.json", "primary_oracle.py", "independent_oracle.py", "check_inventory.py",
    "verify_workload.py",
)


def static_issues() -> list[str]:
    issues = [f"missing package file: {name}" for name in PACKAGE_FILES
              if not (PACKAGE / name).is_file()]
    issues.extend(f"missing language source: {path}" for path in LANGUAGE_FILES.values()
                  if not (REPO_ROOT / path).is_file())
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return issues + ["workload.json is unreadable or invalid JSON"]
    if workload.get("algorithm") != ALGORITHM:
        issues.append("workload algorithm name does not match")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("workload ABI does not match")
    if workload.get("input", {}).get("maximum_valid_length") != 98:
        issues.append("maximum valid input length does not match the bounded frame")
    if workload.get("input", {}).get("parseable_length") != 99:
        issues.append("parseable input length does not include the trailing-word probe")
    if workload.get("output", {}).get("maximum_bytes") != 352:
        issues.append("maximum output byte count does not match the trace bound")
    if workload.get("workspace", {}).get("bytes") != 16384:
        issues.append("workspace metadata does not match the package cap")
    min_literal = -(1 << 63)
    if not any(
        case.get("id") == "i64-minimum-literal-rejected-before-magnitude-conversion"
        and case.get("input_values") == [1, 1, 1, min_literal, 0, 0]
        and case.get("expected_result") == -1
        for case in workload.get("cases", [])
        if isinstance(case, dict)
    ):
        issues.append("workload is missing the signed-i64-minimum malformed-literal probe")
    return issues


def check_inventory() -> list[str]:
    return static_issues()


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
