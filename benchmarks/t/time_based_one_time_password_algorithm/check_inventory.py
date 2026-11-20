"""Check package paths and declared bounds without running benchmark code."""

from __future__ import annotations

import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
SYMBOL = "time_based_one_time_password_algorithm"
PORTS = {
    "c": "c/t/time_based_one_time_password_algorithm.c",
    "c3": "c3/t/time_based_one_time_password_algorithm.c3",
    "cpp": "cpp/t/time_based_one_time_password_algorithm.cpp",
    "elisa": "elisa/t/time_based_one_time_password_algorithm.elisa",
    "mojo": "mojo/t/time_based_one_time_password_algorithm.mojo",
    "nim": "nim/t/time_based_one_time_password_algorithm.nim",
    "odin": "odin/t/time_based_one_time_password_algorithm.odin",
    "rust": "rust/t/time_based_one_time_password_algorithm.rs",
    "v": "v/t/time_based_one_time_password_algorithm.v",
    "zig": "zig/t/time_based_one_time_password_algorithm.zig",
}


def verify_static_inventory() -> list[str]:
    errors: list[str] = []
    inventory = json.loads((PACKAGE / "inventory.json").read_text())
    workload = json.loads((PACKAGE / "workload.json").read_text())
    expected_paths = {language: f"../../../{path}" for language, path in PORTS.items()}
    if inventory.get("ports") != expected_paths:
        errors.append("inventory port map mismatch")
    if inventory.get("algorithm") != SYMBOL or inventory.get("function_symbol") != SYMBOL:
        errors.append("inventory symbol mismatch")
    if inventory.get("abi") != "i64_array_bytes_output":
        errors.append("inventory ABI mismatch")
    if inventory.get("workload_verifier") != "verify_workload.py":
        errors.append("workload verifier metadata mismatch")
    if inventory.get("suite_status") != "integrated":
        errors.append("suite registration status mismatch")
    if workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL:
        errors.append("workload symbol mismatch")
    if workload.get("abi") != "i64_array_bytes_output":
        errors.append("workload ABI mismatch")
    if workload.get("input", {}).get("maximum_valid_length") != 66:
        errors.append("maximum valid input length mismatch")
    if workload.get("input", {}).get("maximum_parseable_length") != 67:
        errors.append("maximum parseable input length mismatch")
    if workload.get("contract", {}).get("key_length_range") != [16, 64]:
        errors.append("key length domain mismatch")
    if workload.get("output", {}).get("maximum_bytes") != 6:
        errors.append("maximum output size mismatch")
    if workload.get("workspace", {}).get("bytes") != 1024:
        errors.append("workspace bound mismatch")
    if len(PORTS) != 10:
        errors.append("expected exactly ten native ports")

    for language, relative in PORTS.items():
        source_path = ROOT / relative
        if not source_path.is_file():
            errors.append(f"missing {language} source: {relative}")
        elif SYMBOL not in source_path.read_text():
            errors.append(f"missing export symbol in {language}: {relative}")

    required = (
        "README.md", "RIGHTS.md", "INVENTORY.md", "primary_oracle.py",
        "independent_oracle.py", "workload.json", "inventory.json",
        "check_inventory.py", "verify_workload.py",
    )
    for name in required:
        if not (PACKAGE / name).is_file():
            errors.append(f"missing package artifact: {name}")

    ids: set[str] = set()
    for case in workload.get("cases", []):
        case_id = case.get("id")
        if not isinstance(case_id, str) or case_id in ids:
            errors.append(f"missing or repeated case ID: {case_id}")
        ids.add(case_id)
        values = case.get("input_values", [])
        if case.get("input_length") != len(values):
            errors.append(f"input length mismatch in {case_id}")
        if case.get("input_length", 0) > 67:
            errors.append(f"input exceeds parser cap in {case_id}")
        if case.get("output_capacity", 6) > 6:
            errors.append(f"output capacity exceeds bound in {case_id}")
        if "expected_result" not in case or not isinstance(case.get("expected_output_hex"), str):
            errors.append(f"missing pinned result/bytes in {case_id}")
        if case.get("input_is_null") and case.get("expected_result") != -1:
            errors.append(f"null-input result mismatch in {case_id}")
        if case.get("output_is_null") and case.get("expected_result") != -2:
            errors.append(f"null-output result mismatch in {case_id}")

    for name in ("primary_oracle.py", "independent_oracle.py"):
        source = (PACKAGE / name).read_text()
        for declaration in (
            "MAX_VALID_INPUT_LENGTH = 66",
            "MAX_PARSEABLE_INPUT_LENGTH = 67",
            "MAX_OUTPUT_BYTES = 6",
            "WORKSPACE_BYTES = 1024",
        ):
            if declaration not in source:
                errors.append(f"{name} missing {declaration}")
    if "hmac.new" not in (PACKAGE / "primary_oracle.py").read_text():
        errors.append("primary reference is missing stdlib HMAC")
    independent = (PACKAGE / "independent_oracle.py").read_text()
    if "def _compress" not in independent or "hashlib" in independent or "hmac" in independent:
        errors.append("independent reference is not a local SHA-1/HMAC implementation")
    return errors


def static_issues() -> list[str]:
    return verify_static_inventory()


if __name__ == "__main__":
    problems = verify_static_inventory()
    if problems:
        raise SystemExit("\n".join(problems))
