"""Static fixture, contract, port, and local-link inventory for this package."""

from __future__ import annotations

import importlib.util
import json
import re
from pathlib import Path
from typing import Any


PACKAGE_DIR = Path(__file__).resolve().parent
EXPECTED_PORTS = {
    "C": ("../../../c/a/adaptive_bottom_up_graph_cut_merging.c", "adaptive_bottom_up_graph_cut_merging"),
    "C3": ("../../../c3/a/adaptive_bottom_up_graph_cut_merging.c3", "adaptive_bottom_up_graph_cut_merging"),
    "C++": ("../../../cpp/a/adaptive_bottom_up_graph_cut_merging.cpp", "adaptive_bottom_up_graph_cut_merging"),
    "Elisa": ("../../../elisa/a/adaptive_bottom_up_graph_cut_merging.elisa", "adaptive_bottom_up_graph_cut_merging"),
    "Mojo": ("../../../mojo/a/adaptive_bottom_up_graph_cut_merging.mojo", "adaptive_bottom_up_graph_cut_merging"),
    "Nim": ("../../../nim/a/adaptive_bottom_up_graph_cut_merging.nim", "adaptive_bottom_up_graph_cut_merging"),
    "Odin": ("../../../odin/a/adaptive_bottom_up_graph_cut_merging.odin", "adaptive_bottom_up_graph_cut_merging"),
    "Rust": ("../../../rust/a/adaptive_bottom_up_graph_cut_merging.rs", "adaptive_bottom_up_graph_cut_merging"),
    "V": ("../../../v/a/adaptive_bottom_up_graph_cut_merging.v", "adaptive_bottom_up_graph_cut_merging"),
    "Zig": ("../../../zig/a/adaptive_bottom_up_graph_cut_merging.zig", "adaptive_bottom_up_graph_cut_merging"),
}


def _load_oracle(name: str):
    path = PACKAGE_DIR / f"{name}.py"
    spec = importlib.util.spec_from_file_location(f"abm_{name}", path)
    if spec is None or spec.loader is None:
        raise ImportError(f"could not load {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def verify(workload: dict[str, Any] | None = None) -> list[str]:
    """Return inventory issues without invoking any benchmark or language toolchain."""
    issues: list[str] = []
    if workload is None:
        try:
            workload = json.loads((PACKAGE_DIR / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload.json: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be a JSON object"]

    required = {
        "algorithm": "adaptive_bottom_up_graph_cut_merging",
        "function_symbol": "adaptive_bottom_up_graph_cut_merging",
        "abi": "i64_array_scalar",
        "id": "liu-sun-adaptive-bottom-up-graph-cut-merging-i64-array-scalar-v1",
    }
    for key, value in required.items():
        if workload.get(key) != value:
            issues.append(f"workload.{key} must be {value!r}")

    try:
        primary = _load_oracle("primary_oracle")
        independent = _load_oracle("independent_oracle")
    except (OSError, ImportError, AttributeError) as error:
        return issues + [f"cannot load both oracle modules: {error}"]

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload.cases must be a nonempty array"]
    seen_ids: set[str] = set()
    for index, case in enumerate(cases):
        label = f"cases[{index}]"
        if not isinstance(case, dict):
            issues.append(f"{label} must be an object")
            continue
        case_id = case.get("id")
        if not isinstance(case_id, str) or not case_id:
            issues.append(f"{label}.id must be a nonempty string")
        elif case_id in seen_ids:
            issues.append(f"duplicate fixture id {case_id!r}")
        else:
            seen_ids.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        expected = case.get("expected_result")
        if (not isinstance(values, list) or type(length) is not int or
                type(is_null) is not bool or type(expected) is not int or
                any(type(value) is not int for value in values)):
            issues.append(f"{label} has malformed input or expected-result metadata")
            continue
        primary_result = primary.expected_result(values, input_is_null=is_null, input_length=length)
        independent_result = independent.expected_result(values, input_is_null=is_null, input_length=length)
        if primary_result != expected:
            issues.append(f"{label} expected_result disagrees with primary oracle ({primary_result})")
        if independent_result != expected:
            issues.append(f"{label} expected_result disagrees with independent oracle ({independent_result})")
        if not is_null and length != len(values):
            issues.append(f"{label} input_length must match input_values length")

    max_input_case = next((case for case in cases if isinstance(case, dict) and case.get("id") == "maximum-frame-and-result"), None)
    if max_input_case is None or max_input_case.get("input_length") != 91 or max_input_case.get("expected_result") != 56:
        issues.append("maximum-frame-and-result must cover 91 words and result 56")
    input_contract = workload.get("input")
    if not isinstance(input_contract, dict):
        issues.append("workload.input must be an object")
        input_contract = {}
    for name, maximum in (("maximum_valid_input_length", 91), ("maximum_parseable_input_length", 92)):
        if input_contract.get(name) != maximum:
            issues.append(f"workload.input.{name} must be {maximum}")

    readme_path = PACKAGE_DIR / "README.md"
    rights_path = PACKAGE_DIR / "RIGHTS.md"
    for path in (readme_path, rights_path):
        if not path.is_file():
            issues.append(f"missing {path.name}")
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        for language, (relative, symbol) in EXPECTED_PORTS.items():
            if f"]({relative})" not in readme:
                issues.append(f"README.md has no correctly targeted {language} port link")
            source_path = (PACKAGE_DIR / relative).resolve()
            if not source_path.is_file():
                issues.append(f"missing {language} port at {relative}")
            elif symbol not in source_path.read_text(encoding="utf-8"):
                issues.append(f"{language} port does not expose {symbol}")
        for target in re.findall(r"\]\(([^)]+)\)", readme):
            if target.startswith(("https://", "http://", "mailto:", "#")):
                continue
            local_target = target.split("#", 1)[0]
            if local_target and not (PACKAGE_DIR / local_target).resolve().exists():
                issues.append(f"README.md has unresolved local link {target!r}")
        for phrase in ("descending static potential score", "ascending unordered block-ID pair",
                       "Edmonds–Karp", "does not claim byte-for-byte"):
            if phrase not in readme:
                issues.append(f"README.md is missing profile statement {phrase!r}")

    source = workload.get("source", {})
    for key in ("paper_doi", "review", "authors_mit_reimplementation"):
        if not isinstance(source, dict) or not isinstance(source.get(key), str) or not source[key].startswith("https://"):
            issues.append(f"workload.source.{key} must be a direct HTTPS source link")
    return issues
