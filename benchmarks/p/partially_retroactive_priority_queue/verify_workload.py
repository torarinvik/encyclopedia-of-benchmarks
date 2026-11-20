"""Static workload, reference, and source inventory review for the package."""

from __future__ import annotations

import json
from pathlib import Path
import re

from .independent_oracle import expected_result as independent_expected
from .primary_oracle import (
    MAX_N,
    MAX_OUTPUT_BYTES,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_Q,
    expected_result as primary_expected,
)

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "partially_retroactive_priority_queue"
PORTS = (
    "c/p/partially_retroactive_priority_queue.c",
    "c3/p/partially_retroactive_priority_queue.c3",
    "cpp/p/partially_retroactive_priority_queue.cpp",
    "elisa/p/partially_retroactive_priority_queue.elisa",
    "mojo/p/partially_retroactive_priority_queue.mojo",
    "nim/p/partially_retroactive_priority_queue.nim",
    "odin/p/partially_retroactive_priority_queue.odin",
    "rust/p/partially_retroactive_priority_queue.rs",
    "v/p/partially_retroactive_priority_queue.v",
    "zig/p/partially_retroactive_priority_queue.zig",
)


def verify_workload(workload: object | None = None) -> list[str]:
    issues: list[str] = []
    required = ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                "primary_oracle.py", "independent_oracle.py", "verify_workload.py")
    for name in required:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    for relative in PORTS:
        source = ROOT / relative
        if not source.is_file() or SYMBOL not in source.read_text(encoding="utf-8"):
            issues.append(f"missing exported port: {relative}")
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload must be an object"]
    input_meta = workload.get("input")
    output_meta = workload.get("output")
    workspace = workload.get("workspace")
    source = workload.get("source")
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"):
        issues.append("workload identity or ABI differs")
    if (not isinstance(input_meta, dict)
            or input_meta.get("n_range") != [1, MAX_N]
            or input_meta.get("q_range") != [1, MAX_Q]
            or input_meta.get("maximum_valid_length") != MAX_PARSEABLE_INPUT_LENGTH - 1
            or input_meta.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or input_meta.get("invalid_input_result") != -1):
        issues.append("input framing or bounds differ")
    if (not isinstance(output_meta, dict)
            or output_meta.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or output_meta.get("invalid_input_result") != -1
            or output_meta.get("null_output_result") != -2):
        issues.append("output encoding or bounds differ")
    if (not isinstance(workspace, dict)
            or workspace.get("bytes") != MAX_OUTPUT_BYTES):
        issues.append("workspace must describe the maximum caller output buffer")
    if (not isinstance(source, dict)
            or source.get("commit") != "494ddf7a14d6e49759047a270aa37a1302592cbc"
            or "open" not in str(source.get("implementation_status", ""))):
        issues.append("source metadata must retain the pinned open-proposal status")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases must be nonempty"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid fixture record")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture id: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        result = case.get("expected_result")
        input_is_null = case.get("input_is_null", False)
        output_is_null = case.get("output_is_null", False)
        capacity = case.get("output_capacity", MAX_OUTPUT_BYTES)
        if (not isinstance(values, list) or type(length) is not int
                or type(result) is not int or type(input_is_null) is not bool
                or type(output_is_null) is not bool or type(capacity) is not int):
            issues.append(f"invalid fixture fields: {case_id}")
            continue
        if (primary_expected(values, input_is_null, length, output_is_null, capacity)
                != (result, bytes.fromhex(case.get("expected_output_hex", "")))
                or independent_expected(values, input_is_null, length,
                                        output_is_null, capacity)
                != (result, bytes.fromhex(case.get("expected_output_hex", "")))):
            issues.append(f"dual-reference mismatch: {case_id}")
    readme = PACKAGE / "README.md"
    rights = PACKAGE / "RIGHTS.md"
    if readme.is_file() and rights.is_file():
        text = readme.read_text(encoding="utf-8")
        rights_text = rights.read_text(encoding="utf-8")
        for url in ("https://github.com/yosupo06/library-checker-problems/pull/1411",
                    "https://doi.org/10.1145/1240233.1240236"):
            if url not in text or url not in rights_text:
                issues.append(f"missing provenance link: {url}")
        for target in re.findall(r"\]\(([^)]+)\)", text):
            if target.startswith(("http://", "https://", "#")):
                continue
            if not (PACKAGE / target.split("#", 1)[0]).resolve().is_file():
                issues.append(f"broken README target: {target}")
    return issues


static_issues = verify_workload
