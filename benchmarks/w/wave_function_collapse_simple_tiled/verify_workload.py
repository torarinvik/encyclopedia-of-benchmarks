"""Static fixture, contract, source, and reference reconciler; not run here."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SYMBOL = "wave_function_collapse_simple_tiled"
PORTS = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "single-cell-single-tile", "weighted-choice-first-tile", "weighted-choice-upper-tile",
    "row-major-mrv-tie", "initial-fifo-propagation-reduces-domain",
    "initial-unsupported-singleton-contradiction", "weighted-choice-contradiction-no-backtrack",
    "invalid-empty-domain", "invalid-asymmetric-adjacency", "invalid-trailing-value",
    "invalid-null-input", "maximum-grid-and-tile-count",
}


def _load_reference(filename: str):
    path = PACKAGE / filename
    spec = importlib.util.spec_from_file_location(path.stem, path)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load reference source: {filename}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def workload_issues(workload=None) -> list[str]:
    issues: list[str] = []
    for filename in (
        "README.md", "RIGHTS.md", "INVENTORY.md", "INVENTORY.json", "workload.json",
        "primary_oracle.py", "independent_oracle.py", "verify_workload.py", "check_inventory.py",
    ):
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package artifact: {filename}")
    for language, extension in PORTS.items():
        relative = f"{language}/w/{SYMBOL}.{extension}"
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing port: {relative}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"port does not export profile symbol: {relative}")
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            return issues + [f"cannot read workload metadata: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload root must be an object"]

    input_meta = workload.get("input")
    output_meta = workload.get("output")
    algorithm = workload.get("algorithm")
    sources = workload.get("sources")
    if (algorithm != SYMBOL or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or not isinstance(input_meta, dict)
            or input_meta.get("maximum_valid_input_length") != 55
            or input_meta.get("maximum_parseable_input_length") != 56
            or input_meta.get("adjacency_direction_order") != ["north", "east", "south", "west"]
            or "in-queue deduplication" not in input_meta.get("initial_propagation", "")
            or not isinstance(output_meta, dict)
            or output_meta.get("valid_contradiction_result") != -2
            or output_meta.get("valid_success_range") != [4294967296, 8589934591]
            or output_meta.get("backtracking") is not False
            or workload.get("workspace", {}).get("bytes") != 1024
            or not isinstance(sources, list) or len(sources) != 3
            or sources[0].get("doi") != "10.1145/3102071.3110566"
            or sources[0].get("url") != "https://doi.org/10.1145/3102071.3110566"
            or sources[1].get("doi") != "10.1109/TG.2021.3076368"
            or sources[1].get("url") != "https://doi.org/10.1109/TG.2021.3076368"
            or sources[2].get("score") != 12
            or sources[2].get("role") != "title-only discovery"):
        issues.append("workload identity, bounds, queue, or output metadata differ")
    cases = workload.get("cases")
    if not isinstance(cases, list):
        return issues + ["workload cases must be a list"]
    try:
        primary = _load_reference("primary_oracle.py")
        independent = _load_reference("independent_oracle.py")
    except (ImportError, OSError, ValueError) as error:
        return issues + [f"cannot load reference source: {error}"]

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
        expected = case.get("expected_result")
        is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int
                or (not is_null and length != len(values))
                or length > 56
                or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
                or type(is_null) is not bool or type(expected) is not int):
            issues.append(f"invalid scalar input fixture framing: {case_id}")
            continue
        actual_primary = primary.expected_result(values, input_is_null=is_null, input_length=length)
        actual_independent = independent.expected_result(values, input_is_null=is_null, input_length=length)
        if actual_primary != expected or actual_independent != expected:
            issues.append(f"fixture differs from one or both references: {case_id}")

    missing = REQUIRED_CASES - seen
    if missing:
        issues.append("missing required fixtures: " + ", ".join(sorted(missing)))
    for filename, required_terms in {
        "README.md": ("row-major order", "in-queue flag", "no backtracking", "1,024 bytes"),
        "RIGHTS.md": ("clean-room", "no Rosetta task page"),
    }.items():
        source = (PACKAGE / filename).read_text(encoding="utf-8")
        for term in required_terms:
            if term.lower() not in source.lower():
                issues.append(f"{filename} omits required package detail: {term}")
    return issues


if __name__ == "__main__":
    problems = workload_issues()
    if problems:
        raise SystemExit("\n".join(problems))
    print("workload references and static metadata agree")
