"""Static inventory and fixture checks for singleton fingerprint recovery."""

import json
from pathlib import Path

from t.turnstile_one_sparse_fingerprint_recovery.primary_oracle import expected_output as primary
from t.turnstile_one_sparse_fingerprint_recovery.independent_oracle import expected_output as reference

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/t/turnstile_one_sparse_fingerprint_recovery"
ALGORITHM = "turnstile_one_sparse_fingerprint_recovery"
EXTENSIONS = {"c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
              "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
              "v": "v", "zig": "zig"}


def static_issues(workload=None):
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, ValueError) as error:
            return [f"cannot read workload: {error}"]
    if not isinstance(workload, dict) or any(
            not isinstance(workload.get(key), dict) for key in ("input", "output", "provenance", "measurement")):
        return ["workload root and metadata sections must be objects"]
    cases = workload.get("cases")
    if not isinstance(cases, list) or any(not isinstance(case, dict) for case in cases):
        return ["cases must be an array of objects"]
    issues = []
    if (workload.get("schema_version") != 1 or workload.get("algorithm") != ALGORITHM
            or workload.get("function_symbol") != ALGORITHM
            or workload["input"].get("maximum_valid_values") != 259
            or workload["input"].get("maximum_parseable_values") != 260
            or workload["input"].get("kind") != "packed_i64_array"
            or workload["input"].get("layout") != "[N,Q,z,(index,delta)*Q]"
            or workload["input"].get("coordinate_range") != [1, 64]
            or workload["input"].get("update_count_range") != [0, 128]
            or workload["input"].get("delta_range") != [-1000, 1000]
            or workload["input"].get("base_range") != [1, 1000000006]
            or workload["input"].get("invalid_result") != -1
            or workload["output"].get("invalid_result") != -1
            or workload["measurement"].get("comparison_model") != "i64_array_scalar_call"
            or workload["provenance"].get("url") != "https://dimacs.rutgers.edu/~graham/pubs/papers/l0journal.pdf"):
        issues.append("identity, bounds, ABI, or provenance mismatch")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "t" / f"{ALGORITHM}.{extension}"
        if not path.is_file():
            issues.append(f"missing {language} implementation")
        elif ALGORITHM not in path.read_text(encoding="utf-8"):
            issues.append(f"missing symbol name in {language} implementation")
    seen = set()
    for case in cases:
        case_id = case.get("id")
        if not isinstance(case_id, str):
            issues.append("invalid case ID")
            continue
        if case_id in seen:
            issues.append(f"repeated case ID: {case_id}")
        seen.add(case_id)
        values, length = case.get("input_values"), case.get("input_length")
        null, expected = case.get("input_is_null", False), case.get("expected_result")
        if (not isinstance(values, list) or type(length) is not int
                or type(null) is not bool or type(expected) is not int
                or (null and (values or not 0 <= length <= 260))
                or (not null and length != len(values))):
            issues.append(f"invalid fixture framing: {case_id}")
            continue
        if primary(values, null, length) != expected or reference(values, null, length) != expected:
            issues.append(f"oracle disagreement: {case_id}")
    required = {"empty", "zero-index", "negative-mass", "cancellation", "zero-mass",
                "nonintegral-index", "fingerprint-rejects", "base-one-collision", "candidate-out-of-range",
                "invalid-index", "invalid-delta", "invalid-base", "truncated", "trailing", "null-input",
                "base-at-modulus", "negative-index", "negative-delta-below-bound",
                "minimum-i64-update-count", "maximum-i64-update-count",
                "invalid-update-after-cancellation", "maximum-base-negative-delta", "null-input-maximum-length"}
    if not required <= seen:
        issues.append("missing cases: " + ", ".join(sorted(required - seen)))
    collision = next((case for case in cases if case.get("id") == "base-one-collision"), {})
    if collision.get("input_values") != [3, 2, 1, 0, 1, 2, 1] or collision.get("expected_result") != 2:
        issues.append("base-one-collision must demonstrate the accepted multi-sparse vector")
    null_boundary = next((case for case in cases if case.get("id") == "null-input-maximum-length"), {})
    if null_boundary.get("input_is_null") is not True or null_boundary.get("input_length") != 260:
        issues.append("null-input-maximum-length must pass a null pointer with length 260")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    for problem in problems:
        print(problem)
    raise SystemExit(bool(problems))
