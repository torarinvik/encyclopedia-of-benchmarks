"""Static package inventory. The helper is intentionally not executed here."""
from __future__ import annotations

import json
import re
from pathlib import Path

from .primary_oracle import (MAX_OUTPUT_BYTES, MAX_PARSEABLE_INPUT_LENGTH,
                             MAX_VALID_INPUT_LENGTH, WORKSPACE_BYTES)
from .verify_workload import workload_issues

PACKAGE = Path(__file__).resolve().parent
REPO_ROOT = PACKAGE.parents[2]
NAME = "fast_minimal_triangulation"
LANGUAGES = {
    "c": ("c", "c"), "c3": ("c3", "c3"), "cpp": ("cpp", "cpp"),
    "elisa": ("elisa", "elisa"), "mojo": ("mojo", "mojo"),
    "nim": ("nim", "nim"), "odin": ("odin", "odin"),
    "rust": ("rust", "rs"), "v": ("v", "v"), "zig": ("zig", "zig"),
}


def static_issues(workload: object | None = None) -> list[str]:
    problems = workload_issues(workload)
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "inventory.json",
                 "workload.json", "primary_oracle.py", "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / name).is_file(): problems.append(f"missing package artifact: {name}")
    for language, (directory, extension) in LANGUAGES.items():
        path = REPO_ROOT / directory / "f" / f"{NAME}.{extension}"
        if not path.is_file():
            problems.append(f"missing {language} port")
        elif NAME not in path.read_text(encoding="utf-8"):
            problems.append(f"exported symbol absent from {language} port")
    try:
        inventory = json.loads((PACKAGE / "inventory.json").read_text(encoding="utf-8"))
        workload_doc = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        return problems + [f"cannot read inventory/workload: {error}"]
    if inventory.get("algorithm") != NAME or inventory.get("abi") != "i64_array_bytes_output":
        problems.append("inventory identity mismatch")
    if len(inventory.get("languages", {})) != 10:
        problems.append("inventory must list ten language ports")
    inp, out, ws = workload_doc.get("input", {}), workload_doc.get("output", {}), workload_doc.get("workspace", {})
    complexity = workload_doc.get("complexity", {})
    if (inp.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or inp.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or out.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or ws.get("maximum_bytes") != WORKSPACE_BYTES
            or complexity.get("call_count_recurrence") != "T(1)=1; T(s)<=1+s*T(s-1)"
            or complexity.get("maximum_calls_at_n8") != 69281
            or complexity.get("published_fast_bound_claimed") is not False):
        problems.append("documented bounds disagree")
    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        for language, (directory, extension) in LANGUAGES.items():
            target = f"../../../{directory}/f/{NAME}.{extension}"
            if f"]({target})" not in readme: problems.append(f"README link missing: {language}")
        for target in re.findall(r"\]\(([^)]+)\)", readme):
            if target.startswith(("http://", "https://", "#")): continue
            if not (PACKAGE / target).resolve().is_file(): problems.append(f"broken local README link: {target}")
    return problems


def check_inventory(workload: object | None = None) -> bool:
    issues = static_issues(workload)
    if issues: raise ValueError("; ".join(issues))
    return True
