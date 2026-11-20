"""Static inventory and fixture review for nested-catalog fractional cascading."""

from __future__ import annotations

import json
import re
from pathlib import Path
from urllib.parse import unquote

try:
    from .fractional_cascading_subset_chain_oracle import (
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        expected_result as primary_result,
    )
    from .fractional_cascading_subset_chain_verifier_oracle import (
        expected_result as independent_result,
    )
except ImportError:  # Direct import from the benchmarks directory.
    from fractional_cascading_subset_chain_oracle import (
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        expected_result as primary_result,
    )
    from fractional_cascading_subset_chain_verifier_oracle import (
        expected_result as independent_result,
    )

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/f/fractional_cascading_subset_chain"
ALGORITHM = "fractional_cascading_subset_chain"
SOURCE_URL = "https://doi.org/10.1007/BF01840440"
PORTS = {
    "c": ROOT / "c/f/fractional_cascading_subset_chain.c",
    "c3": ROOT / "c3/f/fractional_cascading_subset_chain.c3",
    "cpp": ROOT / "cpp/f/fractional_cascading_subset_chain.cpp",
    "elisa": ROOT / "elisa/f/fractional_cascading_subset_chain.elisa",
    "mojo": ROOT / "mojo/f/fractional_cascading_subset_chain.mojo",
    "nim": ROOT / "nim/f/fractional_cascading_subset_chain.nim",
    "odin": ROOT / "odin/f/fractional_cascading_subset_chain.odin",
    "rust": ROOT / "rust/f/fractional_cascading_subset_chain.rs",
    "v": ROOT / "v/f/fractional_cascading_subset_chain.v",
    "zig": ROOT / "zig/f/fractional_cascading_subset_chain.zig",
}


def static_issues(workload: dict | None = None) -> list[str]:
    """Return package inventory and fixture mismatches without executing ports."""
    issues: list[str] = []
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload metadata: {error}"]
    if not isinstance(workload, dict):
        return ["workload metadata must be an object"]

    if workload.get("algorithm") != ALGORITHM:
        issues.append("unexpected algorithm name")
    if workload.get("function_symbol") != ALGORITHM:
        issues.append("unexpected exported symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("unexpected ABI")
    input_contract = workload.get("input", {})
    if not isinstance(input_contract, dict):
        input_contract = {}
        issues.append("input contract must be an object")
    if input_contract.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH:
        issues.append("maximum valid input length mismatch")
    if input_contract.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH:
        issues.append("maximum parseable input length mismatch")
    output_contract = workload.get("output", {})
    if not isinstance(output_contract, dict) or output_contract.get("kind") != "signed_64_bit_scalar":
        issues.append("unexpected scalar result type")
    if isinstance(output_contract, dict) and output_contract.get("maximum_result") != 44064:
        issues.append("maximum checksum mismatch")
    source = workload.get("source", {})
    if not isinstance(source, dict) or source.get("url") != SOURCE_URL:
        issues.append("source URL mismatch")

    cases = workload.get("cases", [])
    if not isinstance(cases, list):
        return issues + ["workload cases must be a list"]
    for case in cases:
        if not isinstance(case, dict):
            issues.append("workload contains a non-object case")
            continue
        values = case.get("input_values")
        case_id = case.get("id", "<unnamed>")
        if not isinstance(values, list) or case.get("input_length") != len(values):
            issues.append(f"fixture input length mismatch: {case_id}")
            continue
        if len(values) > MAX_PARSEABLE_INPUT_LENGTH:
            issues.append(f"fixture exceeds parseable input bound: {case_id}")
        arguments = {
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        expected = case.get("expected_result")
        if primary_result(values, **arguments) != expected:
            issues.append(f"primary oracle fixture mismatch: {case_id}")
        if independent_result(values, **arguments) != expected:
            issues.append(f"independent oracle fixture mismatch: {case_id}")

    for language, path in PORTS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif ALGORITHM not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text: {path.relative_to(ROOT)}")

    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document: {name}")

    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        if SOURCE_URL not in readme and "10.1007/BF01840440" not in readme:
            issues.append("README missing Part I source attribution")
        if "bounded special case" not in readme:
            issues.append("README must scope the nested-catalog specialization")
        for relative in PORTS:
            target = f"../../../{relative}/f/{ALGORITHM}."
            if f"]({target}" not in readme:
                issues.append(f"README missing language link target prefix: {relative}")
        for link_target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", readme):
            if "://" in link_target or link_target.startswith("mailto:"):
                continue
            local_target = unquote(link_target.split("#", 1)[0])
            if local_target and not (readme_path.parent / local_target).resolve().is_file():
                issues.append(f"README link target does not exist: {link_target}")

    elisa_path = PORTS["elisa"]
    if elisa_path.is_file():
        elisa = elisa_path.read_text(encoding="utf-8")
        if "view[i64]" not in elisa or "input: i64&" not in elisa:
            issues.append("Elisa must use safe internal views and an ABI ref wrapper")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
