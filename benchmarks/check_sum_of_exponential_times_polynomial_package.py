"""Static inventory review for the finite exponential-power-sum package."""

from __future__ import annotations

import json
from pathlib import Path

from sum_of_exponential_times_polynomial_oracle import expected_result
from sum_of_exponential_times_polynomial_verifier_oracle import verify_result

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/s/sum_of_exponential_times_polynomial"
SYMBOL = "sum_of_exponential_times_polynomial"
SOURCE_URL = "https://github.com/yosupo06/library-checker-problems/tree/master/other/sum_of_exponential_times_polynomial"
LANGUAGE_PATHS = {
    "c": ROOT / "c/s/sum_of_exponential_times_polynomial.c",
    "c3": ROOT / "c3/s/sum_of_exponential_times_polynomial.c3",
    "cpp": ROOT / "cpp/s/sum_of_exponential_times_polynomial.cpp",
    "elisa": ROOT / "elisa/s/sum_of_exponential_times_polynomial.elisa",
    "mojo": ROOT / "mojo/s/sum_of_exponential_times_polynomial.mojo",
    "nim": ROOT / "nim/s/sum_of_exponential_times_polynomial.nim",
    "odin": ROOT / "odin/s/sum_of_exponential_times_polynomial.odin",
    "rust": ROOT / "rust/s/sum_of_exponential_times_polynomial.rs",
    "v": ROOT / "v/s/sum_of_exponential_times_polynomial.v",
    "zig": ROOT / "zig/s/sum_of_exponential_times_polynomial.zig",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text())
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload metadata: {error}"]
    source = workload.get("source", {})
    if (workload.get("schema_version") != 1 or workload.get("algorithm") != SYMBOL
            or workload.get("function_symbol") != SYMBOL or source.get("url") != SOURCE_URL
            or source.get("repository_license") != "Apache-2.0"):
        issues.append("unexpected exported function symbol")
    if workload.get("abi") != "i64_array_scalar":
        issues.append("unexpected ABI")
    input_meta = workload.get("input", {})
    if input_meta.get("maximum_valid_length") != 3:
        issues.append("unexpected input frame width")
    if input_meta.get("degree_range") != [0, 32] or input_meta.get("n_range") != [0, 10**18]:
        issues.append("bounded input profile mismatch")
    if workload.get("output", {}).get("modulus") != 998244353:
        issues.append("unexpected output modulus")
    for case in workload.get("cases", []):
        values = case.get("input_values", [])
        length = case.get("input_length")
        result = expected_result(values, input_length=length)
        case_id = case.get("id", "<unknown>")
        if result != case.get("expected_result"):
            issues.append(f"primary oracle mismatch in {case_id}")
        if not verify_result(values, result, input_length=length):
            issues.append(f"independent oracle rejected workload case {case_id}")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if SOURCE_URL not in readme or "Apache-2.0" not in rights:
        issues.append("README or rights note omits source attribution")
    if "binary composition" not in readme or "Eulerian" not in readme or "r=1" not in readme:
        issues.append("README omits algorithm details or edge cases")
    for language, path in LANGUAGE_PATHS.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
        elif SYMBOL not in path.read_text(encoding="utf-8"):
            issues.append(f"missing exported symbol text in {path.relative_to(ROOT)}")
        elif str(path.relative_to(ROOT)) not in readme:
            issues.append(f"README does not link {language} port")
    elisa = LANGUAGE_PATHS["elisa"].read_text(encoding="utf-8")
    if "UnsafePointer" in elisa or "ptr[" in elisa:
        issues.append("Elisa implementation contains an internal raw pointer")
    for name in ("README.md", "RIGHTS.md", "workload.json"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package document {name}")
    for name in (
        "sum_of_exponential_times_polynomial_oracle.py",
        "sum_of_exponential_times_polynomial_verifier_oracle.py",
    ):
        if not (ROOT / "benchmarks" / name).is_file():
            issues.append(f"missing oracle {name}")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
