"""Static workload, oracle, provenance, and ten-port inventory review."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import expected_output as independent_output
    from .primary_oracle import (
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        expected_output as primary_output,
    )
except ImportError:  # Direct invocation from this package directory.
    from independent_oracle import expected_output as independent_output
    from primary_oracle import (
        MAX_OUTPUT_BYTES,
        MAX_PARSEABLE_INPUT_LENGTH,
        MAX_VALID_INPUT_LENGTH,
        expected_output as primary_output,
    )

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "dirichlet_convolution_and_prefix_sums"
WORKSPACE_BYTES = 1024
TASK_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/number_theory/dirichlet_convolution_and_prefix_sums/task.md"
LIMITS_URL = "https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/number_theory/dirichlet_convolution_and_prefix_sums/info.toml"
PORTS = {
    "c": ROOT / "c/d/dirichlet_convolution_and_prefix_sums.c",
    "c3": ROOT / "c3/d/dirichlet_convolution_and_prefix_sums.c3",
    "cpp": ROOT / "cpp/d/dirichlet_convolution_and_prefix_sums.cpp",
    "elisa": ROOT / "elisa/d/dirichlet_convolution_and_prefix_sums.elisa",
    "mojo": ROOT / "mojo/d/dirichlet_convolution_and_prefix_sums.mojo",
    "nim": ROOT / "nim/d/dirichlet_convolution_and_prefix_sums.nim",
    "odin": ROOT / "odin/d/dirichlet_convolution_and_prefix_sums.odin",
    "rust": ROOT / "rust/d/dirichlet_convolution_and_prefix_sums.rs",
    "v": ROOT / "v/d/dirichlet_convolution_and_prefix_sums.v",
    "zig": ROOT / "zig/d/dirichlet_convolution_and_prefix_sums.zig",
}
REQUIRED_CASES = {
    "n-one-unit-prefixes", "n-two-distinct-functions", "n-three-quotient-gap",
    "n-four-mixed-prefixes", "n-ten-constant-one-functions",
    "maximum-quotient-set-and-output", "zero-n", "n-over-local-bound",
    "truncated-prefix-arrays", "extra-word", "zero-prefix-residue",
    "short-output-capacity", "null-output", "null-input",
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
            or workload.get("abi") != "i64_array_bytes_output"
            or source.get("task_url") != TASK_URL
            or source.get("limits_url") != LIMITS_URL
            or source.get("repository_license") != "Apache-2.0"):
        issues.append("workload identity, ABI, or official source attribution mismatch")
    if (workload.get("oracle") != "benchmarks/d/dirichlet_convolution_and_prefix_sums/primary_oracle.py"
            or workload.get("independent_oracle") != "benchmarks/d/dirichlet_convolution_and_prefix_sums/independent_oracle.py"):
        issues.append("oracle metadata paths mismatch")
    input_meta = workload.get("input", {})
    output_meta = workload.get("output", {})
    if (input_meta.get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or input_meta.get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or output_meta.get("maximum_bytes") != MAX_OUTPUT_BYTES
            or workload.get("workspace", {}).get("bytes") != WORKSPACE_BYTES):
        issues.append("bounded input/output/workspace metadata mismatch")
    contract = workload.get("contract", {})
    if (contract.get("local_n_range") != [1, 64]
            or contract.get("maximum_quotient_count") != 15
            or contract.get("modulus") != 998244353):
        issues.append("local quotient-set contract mismatch")

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
        kwargs = {
            "capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": length,
        }
        expected = (case.get("expected_result"), bytes.fromhex(case.get("expected_output_hex", "")))
        primary = primary_output(values, **kwargs)
        independent = independent_output(values, **kwargs)
        if primary != expected or independent != expected:
            issues.append(f"oracle/fixture disagreement: {name}")

    readme_path = PACKAGE / "README.md"
    rights_path = PACKAGE / "RIGHTS.md"
    if not readme_path.is_file() or not rights_path.is_file():
        issues.append("README or RIGHTS document is missing")
    else:
        readme = readme_path.read_text(encoding="utf-8")
        rights = rights_path.read_text(encoding="utf-8")
        if TASK_URL not in readme or LIMITS_URL not in readme or "Apache License 2.0" not in rights:
            issues.append("documentation omits source or rights")
        for language, path in PORTS.items():
            if not path.is_file():
                issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
            elif SYMBOL not in path.read_text(encoding="utf-8"):
                issues.append(f"missing exported symbol text in {language} port")
            elif str(path.relative_to(ROOT)) not in readme:
                issues.append(f"README does not link {language} port")
        elisa = PORTS["elisa"]
        if elisa.is_file():
            source_text = elisa.read_text(encoding="utf-8")
            if ("view[i64]" not in source_text or "mutable view[u8]" not in source_text
                    or "input: i64&" not in source_text):
                issues.append("Elisa should use safe internal views and refs only at the ABI")
    return issues


if __name__ == "__main__":
    for issue in static_issues():
        print(issue)
