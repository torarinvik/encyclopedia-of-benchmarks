"""Package inventory and fixture checks for binary-lifting second MST."""

import json
from pathlib import Path

from s.second_best_mst_binary_lifting.primary_oracle import expected_output as primary
from s.second_best_mst_binary_lifting.independent_oracle import expected_output as independent

ROOT = Path(__file__).resolve().parents[1]
ALGORITHM = "second_best_mst_binary_lifting"
PACKAGE = ROOT / "benchmarks/s" / ALGORITHM
EXTENSIONS = {"c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa", "mojo": "mojo",
              "nim": "nim", "odin": "odin", "rust": "rs", "v": "v", "zig": "zig"}


def static_issues(workload=None):
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, ValueError) as error:
            return [f"cannot read workload: {error}"]
    if not isinstance(workload, dict) or any(not isinstance(workload.get(key), dict)
            for key in ("input", "output", "provenance", "measurement")):
        return ["workload metadata sections must be objects"]
    cases = workload.get("cases")
    if not isinstance(cases, list) or any(not isinstance(case, dict) for case in cases):
        return ["workload cases must be objects in a list"]
    issues = []
    for filename in ("README.md", "RIGHTS.md", "primary_oracle.py", "independent_oracle.py"):
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package file: {filename}")
    if (workload.get("schema_version") != 1 or workload.get("algorithm") != ALGORITHM
            or workload.get("function_symbol") != ALGORITHM
            or workload.get("abi") != "i64_array_scalar"
            or workload["input"].get("layout") != "[N,M,(u,v,w)*M]"
            or workload["input"].get("maximum_valid_values") != 62
            or workload["input"].get("maximum_parseable_values") != 63
            or workload["input"].get("invalid_result") != -1
            or workload["output"].get("invalid_result") != -1
            or workload["provenance"].get("url") != "https://cp-algorithms.com/graph/second_best_mst.html"
            or workload["measurement"].get("comparison_model") != "i64_array_scalar_call"):
        issues.append("identity, ABI, or bounds mismatch")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "s" / f"{ALGORITHM}.{extension}"
        if not path.is_file() or ALGORITHM not in path.read_text(encoding="utf-8"):
            issues.append(f"missing {language} source or symbol")
    seen = set()
    for case in cases:
        case_id = case.get("id")
        values = case.get("input_values")
        length = case.get("input_length")
        null = case.get("input_is_null", False)
        expected = case.get("expected_result")
        if not isinstance(case_id, str) or case_id in seen:
            issues.append("missing or repeated case ID")
            continue
        seen.add(case_id)
        if (not isinstance(values, list) or type(length) is not int or type(null) is not bool
                or type(expected) is not int or (null and (values or not 0 <= length <= 63))
                or (not null and length != len(values))):
            issues.append(f"invalid framing: {case_id}")
            continue
        if primary(values, null, length) != expected or independent(values, null, length) != expected:
            issues.append(f"fixture disagrees with oracle: {case_id}")
    required = {"singleton", "only-tree", "unique-cycle", "second-distinct", "all-equal",
                "zero-weight", "deep-path-equal-maximum", "two-sided-path-equal-maximum",
                "maximum-weight-deep-cycle", "maximum-frame", "edge-count-above-maximum", "dimension-above-maximum",
                "invalid-weight-after-valid-edges", "disconnected", "duplicate-edge", "truncated", "null-input",
                "null-input-maximum-length", "empty-non-null", "weight-above-maximum", "reversed-endpoints"}
    if not required <= seen:
        issues.append("missing cases: " + ", ".join(sorted(required - seen)))
    boundary = next((case for case in cases if case.get("id") == "null-input-maximum-length"), {})
    if boundary.get("input_is_null") is not True or boundary.get("input_length") != 63:
        issues.append("maximum-length null fixture must pass a null pointer with length 63")
    return issues
