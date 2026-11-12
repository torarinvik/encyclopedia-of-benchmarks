"""Static package/workload consistency checks; never runs benchmark code."""

import json
from pathlib import Path


PACKAGE_DIR = Path(__file__).resolve().parent
BENCHMARKS_DIR = PACKAGE_DIR.parents[1]
REPOSITORY_DIR = PACKAGE_DIR.parents[2]
WORKLOAD_PATH = PACKAGE_DIR / "workload.json"
LANGUAGE_SOURCES = {
    "c": ("c", ".c"),
    "c3": ("c3", ".c3"),
    "cpp": ("cpp", ".cpp"),
    "elisa": ("elisa", ".elisa"),
    "mojo": ("mojo", ".mojo"),
    "nim": ("nim", ".nim"),
    "odin": ("odin", ".odin"),
    "rust": ("rust", ".rs"),
    "v": ("v", ".v"),
    "zig": ("zig", ".zig"),
}


def validate_package():
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    symbol = workload["function_symbol"]
    errors = []

    if workload.get("schema_version") != 1:
        errors.append("schema_version must be 1")
    if workload.get("algorithm") != symbol:
        errors.append("algorithm and function_symbol must match")
    if workload.get("abi") != "i64_array_bytes_output":
        errors.append("unexpected ABI")
    for document in ("README.md", "RIGHTS.md"):
        if not (PACKAGE_DIR / document).is_file():
            errors.append(f"missing package document: {document}")

    for language, (directory, extension) in LANGUAGE_SOURCES.items():
        source = REPOSITORY_DIR / directory / "b" / f"{symbol}{extension}"
        if not source.is_file():
            errors.append(f"missing {language} port: {source.relative_to(REPOSITORY_DIR)}")
    for oracle in (
        BENCHMARKS_DIR / f"{symbol}_oracle.py",
        BENCHMARKS_DIR / f"{symbol}_oracle_independent.py",
    ):
        if not oracle.is_file():
            errors.append(f"missing oracle: {oracle.relative_to(REPOSITORY_DIR)}")

    contract_input = workload["input"]
    maximum_length = contract_input["maximum_valid_length"]
    cases = workload.get("cases", [])
    if not cases:
        errors.append("workload must contain cases")
    for case in cases:
        values = case.get("input_values", [])
        if case.get("input_length") != len(values):
            errors.append(f"{case.get('id')}: input_length does not match input_values")
        if len(values) > maximum_length:
            errors.append(f"{case.get('id')}: input exceeds maximum_valid_length")
        try:
            encoded = bytes.fromhex(case.get("expected_output_hex", ""))
        except ValueError:
            errors.append(f"{case.get('id')}: expected_output_hex is malformed")
            continue
        result = case.get("expected_result")
        if result is not None and result >= 0:
            if len(encoded) != result:
                errors.append(f"{case.get('id')}: successful result differs from encoded byte length")
        elif encoded:
            errors.append(f"{case.get('id')}: error case must have empty expected output")

    return errors


def verify_workload() -> int:
    errors = validate_package()
    if errors:
        raise ValueError("Bodytrack package is incomplete: " + "; ".join(errors))
    workload = json.loads(WORKLOAD_PATH.read_text(encoding="utf-8"))
    return len(workload.get("cases", []))


if __name__ == "__main__":
    verify_workload()
    print("Bodytrack workload and package files are consistent.")
