"""Static artifact, fixture, and oracle inventory checker; intentionally unrun."""
from __future__ import annotations

import json
import re
from pathlib import Path

from .independent_oracle import expected_values as independent_values
from .primary_oracle import expected_values as primary_values
from benchmarks.bkp_speed_scaling_trace_oracle import expected_output as primary_output
from benchmarks.bkp_speed_scaling_trace_verifier_oracle import expected_output as independent_output

PACKAGE = Path(__file__).resolve().parent
REPO_ROOT = Path(__file__).resolve().parents[3]
NAME = "bkp_speed_scaling_trace"
LANGUAGES = {
    "c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
    "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
    "v": "v", "zig": "zig",
}
REQUIRED_CASES = {
    "single-job-deadline-candidate", "multi-job-window-sums-original-work",
    "single-job-release-crossing", "idle-mask", "ordered-samples-with-idle",
    "maximum-bounds-output", "future-job-marked-unfinished",
    "trailing-value", "insufficient-output-capacity", "null-output", "null-input",
}


def static_issues(workload: object | None = None) -> list[str]:
    if workload is None:
        try:
            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, ValueError) as error:
            return [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    issues: list[str] = []
    input_meta = workload.get("input")
    output_meta = workload.get("output")
    if (workload.get("schema_version") != 1 or workload.get("algorithm") != NAME
            or workload.get("function_symbol") != NAME
            or workload.get("abi") != "i64_array_bytes_output"
            or not isinstance(input_meta, dict)
            or input_meta.get("encoding") != "[job_count,sample_count,(release,deadline,work)*job_count,(time,unfinished_mask)*sample_count]"
            or input_meta.get("job_count_range") != [1, 4]
            or input_meta.get("sample_count_range") != [1, 8]
            or input_meta.get("e_rational") != [271828, 100000]
            or not isinstance(output_meta, dict)
            or output_meta.get("maximum_bytes") != 136
            or output_meta.get("maximum_values") != 17):
        issues.append("identity, bounds, or output contract mismatch")

    for language, extension in LANGUAGES.items():
        path = REPO_ROOT / language / "b" / f"{NAME}.{extension}"
        if not path.is_file():
            issues.append(f"missing language port: {language}")
        elif NAME not in path.read_text(encoding="utf-8"):
            issues.append(f"exported symbol missing from: {language}")
    for filename in ("README.md", "RIGHTS.md", "INVENTORY.md", "workload.json",
                     "primary_oracle.py", "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package artifact: {filename}")

    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        for language, extension in LANGUAGES.items():
            target = f"../../../{language}/b/{NAME}.{extension}"
            if f"]({target})" not in readme:
                issues.append(f"README port target missing: {language}")
        for target in re.findall(r"\]\(([^)]+)\)", readme):
            if target.startswith(("http://", "https://", "#")):
                continue
            if not (PACKAGE / target).resolve().is_file():
                issues.append(f"README local target does not resolve: {target}")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["fixture cases are missing"]
    seen: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("malformed fixture record")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate fixture id: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        input_null = case.get("input_is_null", False)
        output_null = case.get("output_is_null", False)
        capacity = case.get("output_capacity")
        if (not isinstance(values, list) or any(type(x) is not int for x in values)
                or type(length) is not int or length != len(values)
                or type(input_null) is not bool or type(output_null) is not bool
                or (input_null and values) or type(capacity) is not int):
            issues.append(f"invalid fixture framing: {case_id}")
            continue
        args = (values, capacity, output_null, input_null, length)
        expected_result = case.get("expected_result")
        expected_hex = case.get("expected_output_hex")
        primary = primary_output(*args)
        independent = independent_output(*args)
        if (type(expected_result) is not int or not isinstance(expected_hex, str)
                or primary != independent or primary[0] != expected_result
                or primary[1].hex() != expected_hex):
            issues.append(f"oracle/fixture disagreement: {case_id}")
        if not input_null:
            fields = primary_values(values, input_null, length)
            if fields != independent_values(values, input_null, length):
                issues.append(f"value references disagree: {case_id}")
    if seen != REQUIRED_CASES:
        issues.append("fixture inventory mismatch")
    return issues


def verify(workload: object | None = None) -> bool:
    issues = static_issues(workload)
    if issues:
        raise ValueError("; ".join(issues))
    return True


if __name__ == "__main__":
    verify()
