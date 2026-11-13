"""Static workload, oracle, provenance, and ten-port inventory review."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import expected_result as independent_result
    from .primary_oracle import (
        MAX_N,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        expected_result as primary_result,
    )
except ImportError:  # Direct invocation from this package directory.
    from independent_oracle import expected_result as independent_result
    from primary_oracle import (
        MAX_N,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        expected_result as primary_result,
    )

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "pfaffian_of_matrix"
TASK_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/linear_algebra/pfaffian_of_matrix/task.md"
LIMITS_URL = "https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/linear_algebra/pfaffian_of_matrix/info.toml"
PORTS = {
    "c": ROOT / "c/p/pfaffian_of_matrix.c",
    "c3": ROOT / "c3/p/pfaffian_of_matrix.c3",
    "cpp": ROOT / "cpp/p/pfaffian_of_matrix.cpp",
    "elisa": ROOT / "elisa/p/pfaffian_of_matrix.elisa",
    "mojo": ROOT / "mojo/p/pfaffian_of_matrix.mojo",
    "nim": ROOT / "nim/p/pfaffian_of_matrix.nim",
    "odin": ROOT / "odin/p/pfaffian_of_matrix.odin",
    "rust": ROOT / "rust/p/pfaffian_of_matrix.rs",
    "v": ROOT / "v/p/pfaffian_of_matrix.v",
    "zig": ROOT / "zig/p/pfaffian_of_matrix.zig",
}
REQUIRED_CASES = {
    "two-by-two-single-pivot", "four-by-four-alternating-signs",
    "four-by-four-pivot-partner-swap", "four-by-four-singular-zero-matrix",
    "zero-half-dimension", "nonzero-diagonal",
    "non-alternating-opposite-entries", "entry-outside-field",
    "truncated-matrix", "extra-word", "null-input",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]

    source = workload.get("source", {})
    if (workload.get("schema_version") != 1 or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_scalar"
            or source.get("task_url") != TASK_URL
            or source.get("limits_url") != LIMITS_URL
            or source.get("repository_license") != "Apache-2.0"):
        issues.append("workload identity, ABI, or official attribution mismatch")
    if (workload.get("oracle") != "benchmarks/p/pfaffian_of_matrix/primary_oracle.py"
            or workload.get("independent_oracle") != "benchmarks/p/pfaffian_of_matrix/independent_oracle.py"):
        issues.append("oracle metadata paths mismatch")

    if workload.get("contract", {}).get("half_dimension_range") != [1, MAX_N]:
        issues.append("bounded matrix profile mismatch")
    input_metadata = workload.get("input", {})
    if (input_metadata.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_metadata.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH):
        issues.append("maximum input framing metadata mismatch")

    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases must be a nonempty list"]
    identifiers = {case.get("id") for case in cases if isinstance(case, dict)}
    if len(identifiers) != len(cases) or not REQUIRED_CASES <= identifiers:
        issues.append("fixture IDs are missing or duplicated")
    for case in cases:
        if not isinstance(case, dict):
            issues.append("fixture is not an object")
            continue
        values = case.get("input_values")
        length = case.get("input_length")
        name = case.get("id", "<unnamed>")
        if not isinstance(values, list) or length != len(values):
            issues.append(f"fixture framing mismatch: {name}")
            continue
        kwargs = {"input_length": length, "input_is_null": case.get("input_is_null", False)}
        primary = primary_result(values, **kwargs)
        independent = independent_result(values, **kwargs)
        if primary != independent or primary != case.get("expected_result"):
            issues.append(f"oracle/fixture disagreement: {name}")

    readme_path = PACKAGE / "README.md"
    rights_path = PACKAGE / "RIGHTS.md"
    if not readme_path.is_file() or not rights_path.is_file():
        issues.append("README or RIGHTS document is missing")
    else:
        readme = readme_path.read_text(encoding="utf-8")
        rights = rights_path.read_text(encoding="utf-8")
        if TASK_URL not in readme or LIMITS_URL not in readme or "Apache License 2.0" not in rights:
            issues.append("documentation omits task attribution or rights")
        for language, path in PORTS.items():
            if not path.is_file():
                issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
            elif SYMBOL not in path.read_text(encoding="utf-8"):
                issues.append(f"missing entrypoint text in {language} port")
            elif str(path.relative_to(ROOT)) not in readme:
                issues.append(f"README does not link {language} port")
        elisa = PORTS["elisa"]
        if elisa.is_file():
            source_text = elisa.read_text(encoding="utf-8")
            if "view[i64]" not in source_text or "input: i64&" not in source_text:
                issues.append("Elisa should use an internal safe input view and ABI-only ref")
    return issues


if __name__ == "__main__":
    for issue in static_issues():
        print(issue)
