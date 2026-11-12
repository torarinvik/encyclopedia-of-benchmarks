"""Static workload, oracle, provenance, and ten-port inventory checker.

Do not execute this file under the repository's source-only work policy.
"""
from __future__ import annotations

import json
from pathlib import Path

try:
    from .independent_oracle import expected_output as independent_output
    from .primary_oracle import expected_output as primary_output
except ImportError:  # Direct invocation from the package directory.
    from independent_oracle import expected_output as independent_output
    from primary_oracle import expected_output as primary_output

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "brent_kung_fps_composition"
PAPER_URL = "https://doi.org/10.1145/322092.322099"
TASK_URL = "https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/composition_of_formal_power_series_large/task.md"
PORTS = {
    "c": ROOT / "c/b/brent_kung_fps_composition.c",
    "c3": ROOT / "c3/b/brent_kung_fps_composition.c3",
    "cpp": ROOT / "cpp/b/brent_kung_fps_composition.cpp",
    "elisa": ROOT / "elisa/b/brent_kung_fps_composition.elisa",
    "mojo": ROOT / "mojo/b/brent_kung_fps_composition.mojo",
    "nim": ROOT / "nim/b/brent_kung_fps_composition.nim",
    "odin": ROOT / "odin/b/brent_kung_fps_composition.odin",
    "rust": ROOT / "rust/b/brent_kung_fps_composition.rs",
    "v": ROOT / "v/b/brent_kung_fps_composition.v",
    "zig": ROOT / "zig/b/brent_kung_fps_composition.zig",
}
REQUIRED_CASES = {
    "constant-composition", "linear-substitution", "three-term-blocks",
    "identity-inner-series", "sparse-high-block", "five-term-baby-giant",
    "zero-length-invalid", "nonzero-inner-constant-invalid", "coefficient-out-of-range",
    "truncated-input", "extra-input-word",
    "short-output-capacity", "null-output-buffer", "null-input-pointer",
}


def verify() -> list[str]:
    errors: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"workload cannot be read: {error}"]
    source = workload.get("source", {})
    if (workload.get("schema_version") != 1 or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL
            or workload.get("abi") != "i64_array_bytes_output"
            or source.get("paper_doi") != PAPER_URL.removeprefix("https://doi.org/")
            or source.get("task_url") != TASK_URL
            or source.get("repository_license") != "Apache-2.0"):
        errors.append("workload identity or source attribution mismatch")
    if (workload.get("oracle") != "benchmarks/b/brent_kung_fps_composition/primary_oracle.py"
            or workload.get("independent_oracle") != "benchmarks/b/brent_kung_fps_composition/independent_oracle.py"):
        errors.append("oracle paths mismatch")
    contract = workload.get("contract", {})
    if (contract.get("n_range") != [1, 32]
            or contract.get("modulus") != 998244353
            or contract.get("inner_constant_condition") != "b_0 = 0"
            or "Brent" not in contract.get("algorithm", "")
            or "O(N^(5/2))" not in contract.get("algorithm", "")):
        errors.append("bounded Brent–Kung composition contract mismatch")
    if (workload.get("input", {}).get("maximum_valid_length") != 65
            or workload.get("input", {}).get("maximum_parseable_length") != 66
            or workload.get("output", {}).get("maximum_bytes") != 256
            or workload.get("workspace", {}).get("bytes", 0) < 8192):
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
    if TASK_URL not in readme or PAPER_URL not in readme or "No task solution" not in rights:
        errors.append("documentation omits task/paper provenance or clean-room rights note")
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
