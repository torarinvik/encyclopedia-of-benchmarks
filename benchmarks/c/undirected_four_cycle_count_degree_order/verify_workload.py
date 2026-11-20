"""Static package and fixture review; no native implementation is called."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .independent_oracle import expected_result as independent_result
from .primary_oracle import (
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH,
    WORKSPACE_BYTES,
    expected_result as primary_result,
)

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "undirected_four_cycle_count_degree_order"
SOURCE_URL = "https://oi-wiki.org/graph/rings-count/"
PORTS = {
    "c": "c/c/undirected_four_cycle_count_degree_order.c",
    "c3": "c3/c/undirected_four_cycle_count_degree_order.c3",
    "cpp": "cpp/c/undirected_four_cycle_count_degree_order.cpp",
    "elisa": "elisa/c/undirected_four_cycle_count_degree_order.elisa",
    "mojo": "mojo/c/undirected_four_cycle_count_degree_order.mojo",
    "nim": "nim/c/undirected_four_cycle_count_degree_order.nim",
    "odin": "odin/c/undirected_four_cycle_count_degree_order.odin",
    "rust": "rust/c/undirected_four_cycle_count_degree_order.rs",
    "v": "v/c/undirected_four_cycle_count_degree_order.v",
    "zig": "zig/c/undirected_four_cycle_count_degree_order.zig",
}
REQUIRED_CASES = {
    "single-isolated-vertex",
    "four-vertex-path",
    "simple-square",
    "square-with-diagonal",
    "complete-four-graph",
    "diamond",
    "complete-five-graph",
    "complete-bipartite-k2-3",
    "two-disjoint-squares",
    "complete-bipartite-k8-8-maximum-frame",
    "maximum-parseable-trailing-word",
    "duplicate-edge",
    "null-input",
}
MEASUREMENT = {
    "comparison_model": "i64_array_scalar_call",
    "sample_count": 7,
    "warmup_rounds": 2,
    "repetitions_per_sample": 1000,
}


def static_issues(workload: dict[str, Any] | None = None) -> list[str]:
    issues: list[str] = []
    try:
        inventory = json.loads((PACKAGE / "INVENTORY.json").read_text(encoding="utf-8"))
        if workload is None:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
        rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read package metadata: {error}"]
    if not isinstance(inventory, dict) or not isinstance(workload, dict):
        return ["inventory and workload must be JSON objects"]

    contract = inventory.get("contract", {})
    if (inventory.get("algorithm") != SYMBOL
            or inventory.get("function_symbol") != SYMBOL
            or inventory.get("abi") != "i64_array_scalar"
            or inventory.get("source", {}).get("url") != SOURCE_URL
            or contract.get("maximum_valid_input_words") != MAX_VALID_INPUT_LENGTH
            or contract.get("maximum_parseable_input_words") != MAX_PARSEABLE_INPUT_LENGTH
            or contract.get("workspace_bytes") != WORKSPACE_BYTES
            or inventory.get("measurement") != MEASUREMENT):
        issues.append("inventory identity, source, measurement, or bounds differ")
    input_spec = workload.get("input", {})
    if (workload.get("schema_version") != 1
            or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or workload.get("source", {}).get("url") != SOURCE_URL
            or input_spec.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("measurement") != MEASUREMENT
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES):
        issues.append("workload identity, source, measurement, or bounds differ")

    cases = workload.get("cases")
    if not isinstance(cases, list):
        return issues + ["workload cases must be an array"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid fixture record")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture ID: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        expected = case.get("expected_result")
        is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int or length != len(values)
                or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                       for word in values)
                or type(expected) is not int or type(is_null) is not bool):
            issues.append(f"invalid fixture fields: {case_id}")
            continue
        data = None if is_null else values
        primary = primary_result(data, input_is_null=is_null, input_length=length)
        independent = independent_result(data, input_is_null=is_null, input_length=length)
        if primary != independent or primary != expected:
            issues.append(f"fixture/reference mismatch: {case_id}")
    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing fixture IDs: " + ", ".join(sorted(missing)))

    normalized_readme = " ".join(readme.split())
    for phrase in (SOURCE_URL, "(degree, vertex_id)", "K8,8", "5,460", "counting_c4"):
        if phrase not in normalized_readme:
            issues.append(f"README omits contract or provenance detail: {phrase}")
    if SOURCE_URL not in rights or "clean-room" not in rights.lower() or "counting_c4" not in rights:
        issues.append("rights/provenance note is incomplete")

    for language, relative in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing {language} port: {relative}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing {language} symbol: {relative}")
        if inventory.get("languages", {}).get(language) != relative:
            issues.append(f"inventory path differs for {language}")
        if relative not in readme:
            issues.append(f"README omits {language} source path")
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                 "independent_oracle.py", "verify_workload.py", "INVENTORY.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    return issues
