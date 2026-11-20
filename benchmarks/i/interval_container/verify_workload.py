"""Static inventory and fixture-contract review for interval_container."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "interval_container"
MAX_VALID_INPUT_LENGTH = 73
MAX_PARSEABLE_INPUT_LENGTH = 74
PORTS = {
    "c": ("c/i/interval_container.c", ("int64_t interval_container(",)),
    "c3": ("c3/i/interval_container.c3", ('@export("interval_container")', "fn long interval_container(")),
    "cpp": ("cpp/i/interval_container.cpp", ('extern "C" std::int64_t interval_container(',)),
    "elisa": ("elisa/i/interval_container.elisa", ("export fn interval_container(",)),
    "mojo": ("mojo/i/interval_container.mojo", ('@export("interval_container")', "fn interval_container(")),
    "nim": ("nim/i/interval_container.nim", ('exportc: "interval_container"', "proc interval_container*(")),
    "odin": ("odin/i/interval_container.odin", ('interval_container :: proc "c"',)),
    "rust": ("rust/i/interval_container.rs", ('pub unsafe extern "C" fn interval_container(',)),
    "v": ("v/i/interval_container.v", ("@[export: 'interval_container']", "pub fn interval_container(")),
    "zig": ("zig/i/interval_container.zig", ("export fn interval_container(",)),
}


def review() -> list[str]:
    issues: list[str] = []
    for filename in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py",
                     "independent_oracle.py", "verify_workload.py"):
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package file: {filename}")

    readme_path = PACKAGE / "README.md"
    if readme_path.is_file():
        readme = readme_path.read_text(encoding="utf-8")
        for language, (path, _markers) in PORTS.items():
            if f"](../../../{path})" not in readme:
                issues.append(f"missing README source link for {language}")
        for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", readme):
            if target.startswith(("http://", "https://", "mailto:")):
                continue
            if not (PACKAGE / target.split("#", 1)[0]).resolve().is_file():
                issues.append(f"unresolved local README link: {target}")

    for language, (relative, markers) in PORTS.items():
        path = ROOT / relative
        if not path.is_file():
            issues.append(f"missing language port: {relative}")
            continue
        source = path.read_text(encoding="utf-8")
        for marker in markers:
            if marker not in source:
                issues.append(f"missing exported marker in {language}: {marker}")

    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return issues + [f"cannot read workload: {error}"]
    input_spec = workload.get("input", {})
    if (workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or input_spec.get("operation_count_range") != [0, 24]
            or input_spec.get("maximum_valid_input_length") != MAX_VALID_INPUT_LENGTH
            or input_spec.get("maximum_parseable_input_length") != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_valid_result") != 9600):
        issues.append("workload identity, ABI, bounds, or checksum ceiling differs")

    sys.path.insert(0, str(PACKAGE))
    from independent_oracle import expected_result as independent_expected
    from primary_oracle import expected_result as primary_expected

    cases = workload.get("cases", [])
    if not isinstance(cases, list) or len(cases) < 10:
        return issues + ["fixture inventory is incomplete"]
    seen: set[str] = set()
    for case in cases:
        case_id = case.get("id")
        if not isinstance(case_id, str) or case_id in seen:
            issues.append(f"invalid or duplicate fixture id: {case_id}")
            continue
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        expected = case.get("expected_result")
        is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int
                or length != len(values) or type(expected) is not int
                or type(is_null) is not bool):
            issues.append(f"invalid fixture fields: {case_id}")
            continue
        if (primary_expected(values, input_is_null=is_null, input_length=length) != expected
                or independent_expected(values, input_is_null=is_null, input_length=length) != expected):
            issues.append(f"oracle disagreement for fixture: {case_id}")
    if not any(case.get("input_length") == MAX_VALID_INPUT_LENGTH for case in cases):
        issues.append("maximum valid frame is missing")
    if not any(case.get("input_length") == MAX_PARSEABLE_INPUT_LENGTH for case in cases):
        issues.append("maximum parseable malformed frame is missing")
    return issues


if __name__ == "__main__":
    findings = review()
    if findings:
        raise SystemExit("\n".join(findings))
