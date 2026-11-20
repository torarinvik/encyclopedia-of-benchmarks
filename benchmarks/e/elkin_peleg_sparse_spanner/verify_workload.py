"""Static inventory checks for the bounded Elkin–Peleg profile."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .independent_oracle import (
    MAX_INPUT_LENGTH as INDEPENDENT_MAX_INPUT_LENGTH,
    MAX_OUTPUT_BYTES as INDEPENDENT_MAX_OUTPUT_BYTES,
    WORKSPACE_BYTES as INDEPENDENT_WORKSPACE_BYTES,
    expected_output as independent_expected_output,
)
from .primary_oracle import (
    MAX_INPUT_LENGTH,
    MAX_OUTPUT_BYTES,
    WORKSPACE_BYTES,
    expected_output as primary_expected_output,
)

PACKAGE_DIR = Path(__file__).resolve().parent
REPO_ROOT = PACKAGE_DIR.parents[2]
PORTS = {
    "C": "c/e/elkin_peleg_sparse_spanner.c",
    "C3": "c3/e/elkin_peleg_sparse_spanner.c3",
    "C++": "cpp/e/elkin_peleg_sparse_spanner.cpp",
    "Elisa": "elisa/e/elkin_peleg_sparse_spanner.elisa",
    "Mojo": "mojo/e/elkin_peleg_sparse_spanner.mojo",
    "Nim": "nim/e/elkin_peleg_sparse_spanner.nim",
    "Odin": "odin/e/elkin_peleg_sparse_spanner.odin",
    "Rust": "rust/e/elkin_peleg_sparse_spanner.rs",
    "V": "v/e/elkin_peleg_sparse_spanner.v",
    "Zig": "zig/e/elkin_peleg_sparse_spanner.zig",
}


def static_issues(workload: dict[str, Any] | None = None) -> list[str]:
    issues: list[str] = []
    if workload is None:
        try:
            workload = json.loads((PACKAGE_DIR / "workload.json").read_text())
        except (OSError, json.JSONDecodeError) as exc:
            return [f"cannot read workload.json: {exc}"]
    if not isinstance(workload, dict):
        return ["workload root must be an object"]
    expected_header = {
        "algorithm": "elkin_peleg_sparse_spanner",
        "function_symbol": "elkin_peleg_sparse_spanner",
        "abi": "i64_array_bytes_output",
    }
    for key, value in expected_header.items():
        if workload.get(key) != value:
            issues.append(f"{key} must equal {value!r}")
    source = workload.get("source", {})
    if (not isinstance(source, dict)
            or source.get("book_chapter_doi") != "10.1007/978-1-4939-2864-4_387"
            or source.get("paper_doi") != "10.1137/S0097539701393384"):
        issues.append("source attribution must name book DOI 387 and Elkin–Peleg's 2004 paper")
    input_meta = workload.get("input", {})
    if (not isinstance(input_meta, dict)
            or input_meta.get("maximum_valid_length") != 382
            or input_meta.get("maximum_parseable_length") != MAX_INPUT_LENGTH
            or input_meta.get("vertex_count_range") != [1, 20]
            or input_meta.get("edge_count_range") != [0, 190]):
        issues.append("input bounds differ from the bounded simple-graph profile")
    output_meta = workload.get("output", {})
    if (not isinstance(output_meta, dict)
            or output_meta.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or output_meta.get("kind") != "one_byte_per_input_edge"):
        issues.append("output metadata must describe one retention byte per input edge")
    workspace = workload.get("workspace", {})
    if (not isinstance(workspace, dict)
            or workspace.get("bytes") != WORKSPACE_BYTES
            or workspace.get("bytes") != INDEPENDENT_WORKSPACE_BYTES):
        issues.append("workspace.bytes differs from the two bounded reference inventories")
    if (MAX_INPUT_LENGTH != INDEPENDENT_MAX_INPUT_LENGTH
            or MAX_OUTPUT_BYTES != INDEPENDENT_MAX_OUTPUT_BYTES):
        issues.append("primary and independent bounds disagree")

    contract = workload.get("contract", {})
    if (not isinstance(contract, dict)
            or contract.get("parameters", {}).get("kappa") != 4
            or contract.get("parameters", {}).get("epsilon") != "1/2"
            or contract.get("parameters", {}).get("J") != 2
            or contract.get("parameters", {}).get("upsilon") != 64
            or contract.get("ties") is None):
        issues.append("contract must pin the theorem parameters and deterministic tie rules")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["cases must be a nonempty array"]
    identifiers: set[str] = set()
    for case in cases:
        if not isinstance(case, dict):
            issues.append("every case must be an object")
            continue
        case_id = case.get("id")
        if not isinstance(case_id, str) or not case_id or case_id in identifiers:
            issues.append("case identifiers must be nonempty and unique")
            continue
        identifiers.add(case_id)
        values = case.get("input_values")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"{case_id}: input_values and input_length disagree")
            continue
        try:
            expected_hex = bytes.fromhex(case.get("expected_output_hex", ""))
        except (TypeError, ValueError):
            issues.append(f"{case_id}: expected_output_hex is malformed")
            continue
        kwargs = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        primary = primary_expected_output(values, **kwargs)
        independent = independent_expected_output(values, **kwargs)
        wanted = (case.get("expected_result"), expected_hex)
        if primary != independent:
            issues.append(f"{case_id}: primary and independent references disagree")
        if primary != wanted:
            issues.append(f"{case_id}: fixture result/bytes differ from the references")
        if case.get("expected_result", 0) >= 0 and len(expected_hex) != case.get("expected_result"):
            issues.append(f"{case_id}: successful result must equal output byte length")

    for language, relative_path in PORTS.items():
        port = REPO_ROOT / relative_path
        if not port.is_file():
            issues.append(f"missing {language} port: {relative_path}")
        elif "elkin_peleg_sparse_spanner" not in port.read_text(encoding="utf-8"):
            issues.append(f"{language} port does not expose the benchmark symbol: {relative_path}")
    elisa_path = REPO_ROOT / PORTS["Elisa"]
    if elisa_path.is_file():
        elisa_source = elisa_path.read_text(encoding="utf-8")
        if ("values: view[i64] = input[0:length]" not in elisa_source
                or "out: mutable view[u8] = output[0:m]" not in elisa_source
                or "UnsafePointer" in elisa_source):
            issues.append("Elisa port must use bounded safe input/output views internally")
    for filename in ("README.md", "RIGHTS.md", "primary_oracle.py",
                     "independent_oracle.py", "workload.json", "verify_workload.py"):
        if not (PACKAGE_DIR / filename).is_file():
            issues.append(f"missing package artifact: {filename}")
    return issues


def verify() -> list[str]:
    return static_issues()
