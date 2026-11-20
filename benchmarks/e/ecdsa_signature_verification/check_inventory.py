"""Static package inventory checks; source only and not run here."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = Path(__file__).resolve().parent
SYMBOL = "ecdsa_signature_verification"
SOURCES = {
    "c": ROOT / "c/e/ecdsa_signature_verification.c",
    "c3": ROOT / "c3/e/ecdsa_signature_verification.c3",
    "cpp": ROOT / "cpp/e/ecdsa_signature_verification.cpp",
    "elisa": ROOT / "elisa/e/ecdsa_signature_verification.elisa",
    "mojo": ROOT / "mojo/e/ecdsa_signature_verification.mojo",
    "nim": ROOT / "nim/e/ecdsa_signature_verification.nim",
    "odin": ROOT / "odin/e/ecdsa_signature_verification.odin",
    "rust": ROOT / "rust/e/ecdsa_signature_verification.rs",
    "v": ROOT / "v/e/ecdsa_signature_verification.v",
    "zig": ROOT / "zig/e/ecdsa_signature_verification.zig",
}
NULL_GUARDS = {
    "c": "input == NULL",
    "c3": "v==null",
    "cpp": "!v",
    "elisa": "input.is_null()",
    "mojo": "UnsafePointer[Int64,ImmutAnyOrigin]()",
    "nim": "values.isNil",
    "odin": "v==nil",
    "rust": "v.is_null()",
    "v": "v==nil",
    "zig": "v orelse return -1",
}
EXPECTED_CASES = {
    "valid_digest_13_nonce_3_signature",
    "valid_digest_4_nonce_5_signature",
    "r_17_in_scalar_range_above_field_prime",
    "altered_digest_invalidates_signature",
    "altered_s_invalidates_signature",
    "public_point_off_curve",
    "public_x_out_of_range",
    "wrong_field_domain",
    "wrong_base_point_domain",
    "wrong_group_order_domain",
    "zero_r_invalid",
    "zero_s_invalid",
    "digest_scalar_19_reduces_mod_order",
    "digest_conversion_out_of_range",
    "extra_input_word",
    "short_output_capacity",
    "null_output",
    "null_input",
}


def static_issues() -> list[str]:
    issues: list[str] = []
    required = (
        "RESERVATION.md", "README.md", "RIGHTS.md", "INVENTORY.md",
        "INVENTORY.json", "workload.json", "primary_oracle.py",
        "independent_oracle.py", "verify_workload.py", "check_inventory.py",
    )
    for name in required:
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package artifact: {name}")
    for oracle_name in ("primary_oracle.py", "independent_oracle.py"):
        oracle_path = PACKAGE / oracle_name
        if oracle_path.is_file() and "MAX_WORKSPACE_BYTES = 512" not in oracle_path.read_text(encoding="utf-8"):
            issues.append(f"workspace constant mismatch in {oracle_name}")
    for language, path in SOURCES.items():
        if not path.is_file():
            issues.append(f"missing {language} port: {path.relative_to(ROOT)}")
            continue
        source = path.read_text(encoding="utf-8")
        if SYMBOL not in source:
            issues.append(f"missing exported symbol in {path.relative_to(ROOT)}")
        if NULL_GUARDS[language] not in source:
            issues.append(f"missing null-input guard in {path.relative_to(ROOT)}")
        if language == "elisa" and ("values: view[i64]" not in source
                                    or "target: mutable view[u8]" not in source):
            issues.append("Elisa must use bounded input and output views after ABI checks")
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        issues.append(f"invalid workload JSON: {error}")
    else:
        cases = workload.get("cases")
        ids = {case.get("id") for case in cases if isinstance(case, dict)} if isinstance(cases, list) else set()
        if workload.get("algorithm") != SYMBOL or workload.get("function_symbol") != SYMBOL:
            issues.append("workload algorithm/symbol mismatch")
        if workload.get("abi") != "i64_array_bytes_output":
            issues.append("workload ABI mismatch")
        if workload.get("input", {}).get("maximum_valid_input_length") != 11:
            issues.append("valid input bound mismatch")
        if workload.get("input", {}).get("maximum_parseable_input_length") != 12:
            issues.append("parseable input bound mismatch")
        if workload.get("output", {}).get("null_output_result") != -2:
            issues.append("null-output error result mismatch")
        if workload.get("output", {}).get("insufficient_output_capacity_result") != -2:
            issues.append("insufficient-capacity error result mismatch")
        if workload.get("output", {}).get("errors_write_nothing") is not True:
            issues.append("error write contract mismatch")
        if workload.get("workspace", {}).get("bytes") != 512:
            issues.append("workspace bound mismatch")
        if ids != EXPECTED_CASES:
            issues.append("fixture inventory mismatch")
    return issues


if __name__ == "__main__":
    problems = static_issues()
    if problems:
        raise SystemExit("\n".join(problems))
    print("ECDSA package inventory is structurally complete.")
