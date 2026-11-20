"""Static inventory and reference checker for dense bitset Kosaraju SCC."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/k/kosaraju_dense_bitset_scc"
SYMBOL = "kosaraju_dense_bitset_scc"
METHOD_URL = "https://hitonanode.github.io/cplib-cpp/graph/strongly_connected_components_bitset.hpp"
DISCOVERY_URL = "https://github.com/yosupo06/library-checker-problems/issues/1373"
PORTS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "single-isolate", "two-isolates", "two-cycle", "two-sccs",
    "cycle-and-tail-cycle", "dense-eight-one-component",
    "invalid-zero-vertices", "invalid-over-limit", "invalid-unused-high-bit",
    "invalid-signed-high-bit",
    "invalid-short-row-matrix", "invalid-trailing-word", "null-input",
    "short-output", "null-output",
}


def _load_reference(filename: str):
    path = PACKAGE / filename
    spec = importlib.util.spec_from_file_location(path.stem, path)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load reference source: {filename}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def verify_workload(workload=None) -> list[str]:
    issues: list[str] = []
    package_files = (
        "RESERVATION.md", "README.md", "RIGHTS.md", "INVENTORY.md",
        "workload.json", "primary_oracle.py", "independent_oracle.py",
        "verify_workload.py",
    )
    for filename in package_files:
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package artifact: {filename}")
    for language, extension in PORTS.items():
        relative = f"{language}/k/{SYMBOL}.{extension}"
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing port: {relative}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"port does not export the profile symbol: {relative}")

    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload metadata: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload root must be an object"]

    source = workload.get("source")
    discovery = workload.get("discovery")
    input_meta = workload.get("input")
    output_meta = workload.get("output")
    workspace = workload.get("workspace")
    references = workload.get("references")
    if (workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"
            or not isinstance(source, dict) or source.get("url") != METHOD_URL
            or source.get("title") != "Bitset strongly connected components"
            or "iterative two-pass Kosaraju" not in str(source.get("method", ""))
            or not isinstance(discovery, dict) or discovery.get("url") != DISCOVERY_URL
            or discovery.get("issue_number") != 1373
            or discovery.get("title") != "Strongly Connected Components (Dense)"
            or discovery.get("status") != "open proposal"
            or discovery.get("score") is not None
            or "No popularity score" not in str(discovery.get("score_note", ""))
            or not isinstance(input_meta, dict)
            or input_meta.get("vertex_count_range") != [1, 256]
            or input_meta.get("maximum_valid_length") != 1025
            or input_meta.get("maximum_parseable_length") != 1026
            or input_meta.get("word_count_per_row") != "ceil(n/64)"
            or not isinstance(output_meta, dict)
            or output_meta.get("maximum_bytes") != 514
            or output_meta.get("canonical_order") != "ascending minimum vertex"
            or not isinstance(workspace, dict) or workspace.get("bytes") != 32768
            or not isinstance(references, dict)
            or references.get("primary") != "primary_oracle.py: packed-row iterative Kosaraju"
            or references.get("independent") != "independent_oracle.py: adjacency-list Tarjan"
            or references.get("independent_method_url") != "https://doi.org/10.1137/0201010"):
        issues.append("workload identity, bounds, score, or provenance metadata differ")

    try:
        primary = _load_reference("primary_oracle.py")
        independent = _load_reference("independent_oracle.py")
    except (ImportError, OSError, ValueError) as error:
        return issues + [f"cannot load reference source: {error}"]

    cases = workload.get("cases")
    if not isinstance(cases, list):
        return issues + ["workload cases must be a list"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("malformed workload case record")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture ID: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        expected_bytes = case.get("expected_output_bytes")
        expected_result = case.get("expected_result")
        if (not isinstance(values, list) or type(length) is not int or length != len(values)
                or length > 1026
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                       for value in values)
                or not isinstance(expected_bytes, list)
                or any(type(byte) is not int or not 0 <= byte <= 255 for byte in expected_bytes)
                or type(expected_result) is not int):
            issues.append(f"invalid input/output fixture framing: {case_id}")
            continue
        if expected_result != -1 and not case.get("input_is_null", False) and values:
            n = values[0]
            if type(n) is int and 1 <= n <= 256:
                words = (n + 63) // 64
                if length == 1 + n * words:
                    last_bits = n & 63
                    last_mask = (1 << last_bits) - 1 if last_bits else (1 << 64) - 1
                    if any((values[1 + row * words + words - 1] & ((1 << 64) - 1) & ~last_mask)
                           for row in range(n)):
                        issues.append(f"fixture has nonzero unused row bits: {case_id}")
        options = {
            "output_capacity": case.get("output_capacity"),
            "input_is_null": case.get("input_is_null", False),
            "output_is_null": case.get("output_is_null", False),
            "input_length": length,
        }
        expected = (expected_result, bytes(expected_bytes))
        if (primary.expected_output(values, **options) != expected
                or independent.expected_output(values, **options) != expected):
            issues.append(f"fixture differs from one or both references: {case_id}")
        if expected_result > 0 and expected_result != len(expected_bytes):
            issues.append(f"successful fixture byte count differs: {case_id}")
        if expected_result <= 0 and expected_bytes:
            issues.append(f"error fixture must have no output bytes: {case_id}")

    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing required fixtures: " + ", ".join(sorted(missing)))

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    inventory = (PACKAGE / "INVENTORY.md").read_text(encoding="utf-8")
    for required in (METHOD_URL, DISCOVERY_URL, "O(V*ceil(V/64) + E)",
                     "ascending minimum vertex", "32,768 bytes", "iterative two-pass"):
        if required not in readme:
            issues.append(f"README omits profile detail: {required}")
    if "clean-room" not in rights or "10.1137/0201010" not in rights:
        issues.append("rights/provenance note is incomplete")
    if "score` is" not in inventory or "verify_workload.py" not in inventory:
        issues.append("inventory omits score handling or static verifier")
    for language, extension in PORTS.items():
        if f"{language}/k/{SYMBOL}.{extension}" not in readme:
            issues.append(f"README omits source path: {language}/k/{SYMBOL}.{extension}")
    return issues
