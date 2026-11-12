"""Static workload, dual-oracle, provenance, and ten-port inventory checker."""

from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import expected_output as independent_output
    from .primary_oracle import expected_output as primary_output
except ImportError:  # Direct invocation from this package directory.
    from independent_oracle import expected_output as independent_output
    from primary_oracle import expected_output as primary_output

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "sqrt_of_formal_power_series"
TASK_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/sqrt_of_formal_power_series/task.md"
LIMITS_URL = "https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/polynomial/sqrt_of_formal_power_series/info.toml"
PORTS = {
    "c": ROOT / "c/s/sqrt_of_formal_power_series.c",
    "c3": ROOT / "c3/s/sqrt_of_formal_power_series.c3",
    "cpp": ROOT / "cpp/s/sqrt_of_formal_power_series.cpp",
    "elisa": ROOT / "elisa/s/sqrt_of_formal_power_series.elisa",
    "mojo": ROOT / "mojo/s/sqrt_of_formal_power_series.mojo",
    "nim": ROOT / "nim/s/sqrt_of_formal_power_series.nim",
    "odin": ROOT / "odin/s/sqrt_of_formal_power_series.odin",
    "rust": ROOT / "rust/s/sqrt_of_formal_power_series.rs",
    "v": ROOT / "v/s/sqrt_of_formal_power_series.v",
    "zig": ROOT / "zig/s/sqrt_of_formal_power_series.zig",
}
REQUIRED_CASES = {
    "constant-one-canonical-root", "constant-four-choose-small-root", "zero-series",
    "unit-square", "even-valuation-square", "odd-valuation-no-root",
    "nonsquare-constant-no-root", "nonsquare-even-valuation-no-root",
    "zero-length-invalid", "coefficient-out-of-range", "truncated-input",
    "extra-input-word", "short-capacity-root", "short-capacity-no-root",
    "null-output-buffer", "null-input-pointer",
}


def verify() -> list[str]:
    errors: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"workload cannot be read: {error}"]
    source = workload.get("source", {})
    if (workload.get("schema_version") != 1 or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL or workload.get("abi") != "i64_array_bytes_output"
            or source.get("task_url") != TASK_URL or source.get("limits_url") != LIMITS_URL
            or source.get("official_n_max") != 500000
            or source.get("repository_license") != "Apache-2.0"):
        errors.append("workload identity or official source attribution mismatch")
    if (workload.get("oracle") != "benchmarks/s/sqrt_of_formal_power_series/primary_oracle.py"
            or workload.get("independent_oracle") != "benchmarks/s/sqrt_of_formal_power_series/independent_oracle.py"):
        errors.append("oracle paths mismatch")
    contract = workload.get("contract", {})
    if (contract.get("n_range") != [1, 64] or contract.get("modulus") != 998244353
            or contract.get("output_layout", "").find("one little-endian signed 64-bit value -1") < 0
            or "least nonnegative" not in contract.get("root_selection", "")):
        errors.append("bounded square-root contract or canonical selection mismatch")
    if (workload.get("input", {}).get("maximum_valid_length") != 65
            or workload.get("input", {}).get("maximum_parseable_length") != 66
            or workload.get("output", {}).get("maximum_bytes") != 512
            or workload.get("output", {}).get("no_root_result") != 8
            or workload.get("workspace", {}).get("bytes") != 1024):
        errors.append("input, output, or workspace bounds mismatch")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return errors + ["workload must contain named fixtures"]
    identifiers = {case.get("id") for case in cases if isinstance(case, dict)}
    if len(identifiers) != len(cases) or not REQUIRED_CASES <= identifiers:
        errors.append("fixture IDs are missing or duplicated")
    for case in cases:
        if not isinstance(case, dict):
            errors.append("fixture entry is not an object")
            continue
        values = case.get("input_values", [])
        input_length = case.get("input_length")
        null_input = case.get("input_is_null", False)
        primary = primary_output(values, case.get("output_capacity"),
                                 case.get("output_is_null", False), null_input, input_length)
        independent = independent_output(values, case.get("output_capacity"),
                                         case.get("output_is_null", False), null_input, input_length)
        if (input_length != len(values) or primary != independent
                or primary[0] != case.get("expected_result")
                or primary[1].hex() != case.get("expected_output_hex")):
            errors.append(f"fixture/oracle mismatch: {case.get('id')}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if TASK_URL not in readme or LIMITS_URL not in readme or "Apache-2.0" not in rights:
        errors.append("documentation omits task attribution or rights")
    for language, path in PORTS.items():
        if not path.is_file():
            errors.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            errors.append(f"entrypoint missing from {language} port")
        elif str(path.relative_to(ROOT)) not in readme:
            errors.append(f"README does not link {language} port")
    return errors


if __name__ == "__main__":
    for error in verify():
        print(error)
