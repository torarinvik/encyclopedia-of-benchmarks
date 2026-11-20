"""Static workload, oracle, port, and local-link inventory for this package."""

from __future__ import annotations

import importlib.util
import json
import re
from pathlib import Path
from typing import Any


PACKAGE_DIR = Path(__file__).resolve().parent
PORTS = {
    "C": "../../../c/d/dual_decomposition_graph_cut_maxflow.c",
    "C3": "../../../c3/d/dual_decomposition_graph_cut_maxflow.c3",
    "C++": "../../../cpp/d/dual_decomposition_graph_cut_maxflow.cpp",
    "Elisa": "../../../elisa/d/dual_decomposition_graph_cut_maxflow.elisa",
    "Mojo": "../../../mojo/d/dual_decomposition_graph_cut_maxflow.mojo",
    "Nim": "../../../nim/d/dual_decomposition_graph_cut_maxflow.nim",
    "Odin": "../../../odin/d/dual_decomposition_graph_cut_maxflow.odin",
    "Rust": "../../../rust/d/dual_decomposition_graph_cut_maxflow.rs",
    "V": "../../../v/d/dual_decomposition_graph_cut_maxflow.v",
    "Zig": "../../../zig/d/dual_decomposition_graph_cut_maxflow.zig",
}
SYMBOL = "dual_decomposition_graph_cut_maxflow"


def _load_oracle(name: str):
    path = PACKAGE_DIR / f"{name}.py"
    spec = importlib.util.spec_from_file_location(f"ddgc_{name}", path)
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def verify(workload: dict[str, Any] | None = None) -> list[str]:
    """Return package inventory issues without starting any language toolchain."""
    issues: list[str] = []
    if workload is None:
        try:
            workload = json.loads((PACKAGE_DIR / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return [f"cannot read workload.json: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be a JSON object"]
    expected_fields = {
        "algorithm": SYMBOL,
        "function_symbol": SYMBOL,
        "abi": "i64_array_scalar",
        "id": "strandmark-kahl-dual-decomposition-graph-cut-i64-array-scalar-v1",
    }
    for key, value in expected_fields.items():
        if workload.get(key) != value:
            issues.append(f"workload.{key} must be {value!r}")

    try:
        primary = _load_oracle("primary_oracle")
        independent = _load_oracle("independent_oracle")
    except (OSError, ImportError, AttributeError) as error:
        return issues + [f"cannot load both reference modules: {error}"]
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload.cases must be a nonempty array"]

    case_ids: set[str] = set()
    for index, case in enumerate(cases):
        label = f"cases[{index}]"
        if not isinstance(case, dict):
            issues.append(f"{label} must be an object")
            continue
        case_id = case.get("id")
        if not isinstance(case_id, str) or not case_id:
            issues.append(f"{label}.id must be a nonempty string")
        elif case_id in case_ids:
            issues.append(f"duplicate fixture id {case_id!r}")
        else:
            case_ids.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        is_null = case.get("input_is_null", False)
        expected = case.get("expected_result")
        if (not isinstance(values, list) or type(length) is not int or
                type(is_null) is not bool or type(expected) is not int or
                any(type(value) is not int for value in values)):
            issues.append(f"{label} has malformed fixture metadata")
            continue
        if not is_null and length != len(values):
            issues.append(f"{label}.input_length does not match input_values")
        if primary.expected_result(values, input_is_null=is_null, input_length=length) != expected:
            issues.append(f"{label} expected_result disagrees with the primary oracle")
        if independent.expected_result(values, input_is_null=is_null, input_length=length) != expected:
            issues.append(f"{label} expected_result disagrees with the independent oracle")

    maximum_case = next((case for case in cases if isinstance(case, dict) and case.get("id") == "maximum-frame-and-packed-result"), None)
    if (maximum_case is None or maximum_case.get("input_length") != 62 or
            maximum_case.get("expected_result") != 74481):
        issues.append("maximum fixture must exercise 62 words and packed result 74481")
    input_contract = workload.get("input")
    if not isinstance(input_contract, dict):
        issues.append("workload.input must be an object")
        input_contract = {}
    for key, value in (("maximum_valid_input_length", 62), ("maximum_parseable_input_length", 63)):
        if input_contract.get(key) != value:
            issues.append(f"workload.input.{key} must be {value}")

    readme_path = PACKAGE_DIR / "README.md"
    rights_path = PACKAGE_DIR / "RIGHTS.md"
    if not readme_path.is_file():
        issues.append("missing README.md")
    if not rights_path.is_file():
        issues.append("missing RIGHTS.md")
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        for language, relative in PORTS.items():
            if f"]({relative})" not in readme:
                issues.append(f"README.md has no correctly targeted {language} port link")
            target = (PACKAGE_DIR / relative).resolve()
            if not target.is_file():
                issues.append(f"missing {language} port at {relative}")
            elif SYMBOL not in target.read_text(encoding="utf-8"):
                issues.append(f"{language} port does not expose {SYMBOL}")
        for target in re.findall(r"\]\(([^)]+)\)", readme):
            if target.startswith(("https://", "http://", "mailto:", "#")):
                continue
            local = target.split("#", 1)[0]
            if local and not (PACKAGE_DIR / local).resolve().exists():
                issues.append(f"README.md has unresolved local link {target!r}")
        for phrase in ("lcm(2,1,...,T)", "dual lower bound", "maximal sink-side",
                       "never presents disagreement as an exact cut", "LIUSUN and PEIBFS",
                       "region discharge"):
            if phrase not in readme:
                issues.append(f"README.md is missing profile statement {phrase!r}")

    source = workload.get("source")
    if not isinstance(source, dict):
        issues.append("workload.source must be an object")
    else:
        for key in ("paper", "doi"):
            value = source.get(key)
            if not isinstance(value, str) or not value.startswith("https://"):
                issues.append(f"workload.source.{key} must be a direct HTTPS link")
    return issues
