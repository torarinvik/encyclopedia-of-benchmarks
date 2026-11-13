"""Review the Karger trial package and compare its two fixture calculations."""

import json
from pathlib import Path

from k.karger_contraction_trial.primary_oracle import expected_output as primary
from k.karger_contraction_trial.independent_oracle import expected_output as reference

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/k/karger_contraction_trial"
EXTENSIONS = {"c": "c", "cpp": "cpp", "c3": "c3", "elisa": "elisa",
              "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
              "v": "v", "zig": "zig"}


def static_issues(workload=None):
    issues = []
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, ValueError) as error:
            return [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    if any(not isinstance(workload.get(key), dict) for key in ("provenance", "measurement", "input")):
        return ["provenance, measurement, and input metadata must be objects"]
    cases = workload.get("cases")
    if not isinstance(cases, list) or any(not isinstance(case, dict) for case in cases):
        return ["cases must be an array of objects"]
    if (workload.get("algorithm") != "karger_contraction_trial"
            or workload.get("function_symbol") != "karger_contraction_trial"
            or workload.get("schema_version") != 1
            or workload.get("provenance", {}).get("url")
            != "https://people.csail.mit.edu/karger/Papers/contract.pdf"
            or workload.get("measurement", {}).get("comparison_model") != "i64_array_scalar_call"
            or workload.get("input", {}).get("maximum_input_values") != 56
            or workload.get("input", {}).get("maximum_parseable_values") != 57):
        issues.append("identity, provenance, ABI, or input bounds mismatch")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "k" / f"karger_contraction_trial.{extension}"
        if not path.is_file():
            issues.append(f"missing {language} implementation")
        elif "karger_contraction_trial" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol name in {language} implementation")
    seen = set()
    for case in cases:
        case_id = case.get("id")
        if not isinstance(case_id, str):
            issues.append(f"invalid case id: {case_id!r}")
            continue
        if case_id in seen:
            issues.append(f"invalid or repeated case id: {case_id!r}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        null = case.get("input_is_null", False)
        result = case.get("expected_result")
        if (not isinstance(values, list) or type(length) is not int
                or type(null) is not bool or type(result) is not int
                or (null and (values or not 0 <= length <= 57))
                or (not null and length != len(values))):
            issues.append(f"invalid fixture framing: {case_id}")
            continue
        if primary(values, null, length) != result or reference(values, null, length) != result:
            issues.append(f"oracle disagreement: {case_id}")
    if not seen:
        issues.append("no workload cases")
    required = {"single_edge", "parallel_edges", "triangle", "cycle", "uneven_cut",
                "maximum_graph", "disconnected", "self_loop", "vertex_out_of_range",
                "negative_rank", "rank_too_large", "rank_after_internal_edges",
                "truncated", "trailing_value", "null_input", "null_input_max_length"}
    if not required <= seen:
        issues.append("missing required workload cases: " + ", ".join(sorted(required - seen)))
    maximum = next((case for case in cases
                    if case.get("id") == "maximum_graph"), None)
    if maximum is not None and (maximum.get("input_length") != 56
                                or not isinstance(maximum.get("input_values"), list)
                                or maximum["input_values"][:2] != [8, 24]):
        issues.append("maximum graph does not exercise both input bounds")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    for problem in problems:
        print(problem)
    raise SystemExit(bool(problems))
