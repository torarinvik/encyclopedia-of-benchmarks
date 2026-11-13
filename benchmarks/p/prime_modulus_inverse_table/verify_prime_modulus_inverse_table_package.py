"""Inventory checks for the bounded prime-modulus inverse-table package."""

import json
from pathlib import Path

from .primary_oracle import expected_output as primary_output
from .independent_oracle import expected_output as independent_output

ROOT = Path(__file__).resolve().parents[3]
EXTENSIONS = {"c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
              "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
              "v": "v", "zig": "zig"}
NULL_INPUT = {"c": "input == NULL", "c3": "input == null", "cpp": "input == nullptr",
              "elisa": "input.is_null()", "mojo": "UnsafePointer[Int64, ImmutAnyOrigin]()",
              "nim": "input.isNil", "odin": "input == nil", "rust": "input.is_null()",
              "v": "input == nil", "zig": "input == null"}
NULL_OUTPUT = {"c": "output == NULL", "c3": "output == null", "cpp": "output == nullptr",
               "elisa": "output.is_null()", "mojo": "UnsafePointer[UInt8, MutAnyOrigin]()",
               "nim": "output.isNil", "odin": "output == nil", "rust": "output.is_null()",
               "v": "output == nil", "zig": "output == null"}


def static_issues() -> list[str]:
    issues = []
    package = ROOT / "benchmarks/p/prime_modulus_inverse_table"
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py", "independent_oracle.py"):
        if not (package / name).is_file():
            issues.append(f"missing {name}")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "p" / f"prime_modulus_inverse_table.{extension}"
        if not path.is_file():
            issues.append(f"missing {path.relative_to(ROOT)}")
        else:
            source = path.read_text(encoding="utf-8")
            if "prime_modulus_inverse_table" not in source:
                issues.append(f"missing exported symbol in {path.relative_to(ROOT)}")
            if NULL_INPUT[language] not in source or NULL_OUTPUT[language] not in source:
                issues.append(f"missing null guard in {path.relative_to(ROOT)}")
            if language == "elisa" and any(token in source for token in ("UnsafePointer", "*i64", "*u8")):
                issues.append("Elisa source uses raw pointer storage")
    workload_path = package / "workload.json"
    if workload_path.is_file():
        try:
            workload = json.loads(workload_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            issues.append(f"invalid workload: {error}")
        else:
            input_spec = workload.get("input", {})
            output_spec = workload.get("output", {})
            if (workload.get("algorithm") != "prime_modulus_inverse_table"
                    or workload.get("function_symbol") != "prime_modulus_inverse_table"
                    or workload.get("abi") != "i64_array_bytes_output"
                    or input_spec.get("modulus") != 1_000_000_007
                    or input_spec.get("query_count_range") != [0, 32]
                    or input_spec.get("operand_range") != [1, 256]
                    or input_spec.get("maximum_valid_input_length") != 33
                    or input_spec.get("maximum_parseable_input_length") != 34
                    or output_spec.get("maximum_bytes") != 128
                    or workload.get("workspace", {}).get("bytes") != 4096
                    or workload.get("measurement", {}).get("comparison_model") != "i64_array_bytes_output_call"):
                issues.append("workload metadata differs from the bounded inverse-table contract")
            cases = workload.get("cases", [])
            maximum = next((case for case in cases if case.get("id") == "maximum_batch"), {})
            if (len(maximum.get("input_values", [])) != 33
                    or maximum.get("expected_result") != 128
                    or len(maximum.get("expected_output_hex", "")) != 256):
                issues.append("maximum batch does not reach the declared input/output bounds")
    return issues


def verify_workload() -> list[str]:
    """Compare the declared fixtures with both independently structured oracles."""
    issues = static_issues()
    if issues:
        return issues
    workload = json.loads((ROOT / "benchmarks/p/prime_modulus_inverse_table/workload.json").read_text(encoding="utf-8"))
    for case in workload["cases"]:
        kwargs = {"capacity": case.get("output_capacity"),
                  "output_is_null": case.get("output_is_null", False),
                  "input_is_null": case.get("input_is_null", False),
                  "input_length": case.get("input_length")}
        expected = (case["expected_result"], bytes.fromhex(case.get("expected_output_hex", "")))
        for label, oracle in (("primary", primary_output), ("independent", independent_output)):
            if oracle(case["input_values"], **kwargs) != expected:
                issues.append(f"{label} oracle disagrees with {case['id']}")
    return issues
