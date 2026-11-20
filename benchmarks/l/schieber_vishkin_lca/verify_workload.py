"""Static workload and source inventory verifier; never launches language ports."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
BENCHMARKS = ROOT / "benchmarks"
if str(BENCHMARKS) not in sys.path:
    sys.path.insert(0, str(BENCHMARKS))

from schieber_vishkin_lca_independent_oracle import verify_result
from schieber_vishkin_lca_oracle import expected_output

PACKAGE = Path(__file__).resolve().parent
SYMBOL = "schieber_vishkin_lca"
LANGUAGE_PATHS = {
    "c": ROOT / "c/l/schieber_vishkin_lca.c",
    "c3": ROOT / "c3/l/schieber_vishkin_lca.c3",
    "cpp": ROOT / "cpp/l/schieber_vishkin_lca.cpp",
    "elisa": ROOT / "elisa/l/schieber_vishkin_lca.elisa",
    "mojo": ROOT / "mojo/l/schieber_vishkin_lca.mojo",
    "nim": ROOT / "nim/l/schieber_vishkin_lca.nim",
    "odin": ROOT / "odin/l/schieber_vishkin_lca.odin",
    "rust": ROOT / "rust/l/schieber_vishkin_lca.rs",
    "v": ROOT / "v/l/schieber_vishkin_lca.v",
    "zig": ROOT / "zig/l/schieber_vishkin_lca.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text())
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    if workload.get("schema_version") != 1:
        issues.append("unsupported schema version")
    if workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL:
        issues.append("algorithm or function symbol mismatch")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("ABI mismatch")
    source = workload.get("source", {})
    if source.get("title") != "Schieber–Vishkin algorithm" or source.get("title_only_discovery_score") != 21:
        issues.append("title-only source metadata mismatch")
    if source.get("discovery_index_url") != (
        "https://github.com/acmeism/RosettaCodeData/blob/"
        "1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks"
    ):
        issues.append("pinned discovery index mismatch")
    if source.get("primary_reference_url") != "https://doi.org/10.1137/0217079":
        issues.append("primary algorithm reference missing")

    input_meta = workload.get("input", {})
    if input_meta.get("node_count_range") != [1, 256] or input_meta.get("query_count_range") != [0, 1024]:
        issues.append("bounded input ranges mismatch")
    if input_meta.get("maximum_length") != 2562 or input_meta.get("maximum_trailing_frame_probe_length") != 2563:
        issues.append("input frame limits mismatch")
    output_meta = workload.get("output", {})
    if output_meta.get("maximum_bytes") != 1024 or not output_meta.get("output_untouched_on_error"):
        issues.append("output limits or transactional-write rule mismatch")
    if workload.get("workspace", {}).get("logical_scratch_bytes_maximum") != 32768:
        issues.append("logical scratch limit mismatch")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        issues.append("workload cases are missing")
        cases = []
    seen_case_ids: set[str] = set()
    for case in cases:
        case_id = case.get("id")
        if not isinstance(case_id, str) or not case_id or case_id in seen_case_ids:
            issues.append(f"missing or duplicate case id: {case_id!r}")
            continue
        seen_case_ids.add(case_id)
        values = case.get("input_values")
        if not isinstance(values, list):
            issues.append(f"input values are not an array in {case_id}")
            continue
        if case.get("input_length") != len(values):
            issues.append(f"fixture framing mismatch in {case_id}")
        capacity = case.get("output_capacity")
        output_is_null = case.get("output_is_null", False)
        input_is_null = case.get("input_is_null", False)
        result, payload = expected_output(
            values,
            capacity=capacity,
            output_is_null=output_is_null,
            input_is_null=input_is_null,
            input_length=case.get("input_length"),
        )
        if result != case.get("expected_result"):
            issues.append(f"primary result mismatch in {case_id}")
        if payload.hex() != case.get("expected_output_hex"):
            issues.append(f"primary output mismatch in {case_id}")
        if not verify_result(
            values,
            result,
            payload,
            output_capacity=capacity,
            output_is_null=output_is_null,
            input_is_null=input_is_null,
            input_length=case.get("input_length"),
        ):
            issues.append(f"binary-lifting reference rejected {case_id}")

    for language, path in LANGUAGE_PATHS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text():
            issues.append(f"exported symbol text missing from {path.relative_to(ROOT)}")
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact {name}")
    for name in ("schieber_vishkin_lca_oracle.py", "schieber_vishkin_lca_independent_oracle.py"):
        if not (BENCHMARKS / name).is_file():
            issues.append(f"missing reference source {name}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
