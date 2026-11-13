"""Static inventory checks for Newton formal-series reversion."""

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
              "nim": "input == nil", "odin": "input == nil", "rust": "input.is_null()",
              "v": "input == nil", "zig": "input_opt == null"}
NULL_OUTPUT = {"c": "output == NULL", "c3": "output == null", "cpp": "output == nullptr",
               "elisa": "output.is_null()", "mojo": "UnsafePointer[UInt8, MutAnyOrigin]()",
               "nim": "output == nil", "odin": "output == nil", "rust": "output.is_null()",
               "v": "output == nil", "zig": "output_opt == null"}


def static_issues() -> list[str]:
    issues = []
    package = ROOT / "benchmarks/n/newton_compositional_inverse_fps"
    for name in ("README.md", "RIGHTS.md", "workload.json", "primary_oracle.py", "independent_oracle.py"):
        if not (package / name).is_file():
            issues.append(f"missing {name}")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "n" / f"newton_compositional_inverse_fps.{extension}"
        if not path.is_file():
            issues.append(f"missing {path.relative_to(ROOT)}")
        else:
            source = path.read_text(encoding="utf-8")
            if "newton_compositional_inverse_fps" not in source:
                issues.append(f"missing symbol in {path.relative_to(ROOT)}")
            if NULL_INPUT[language] not in source or NULL_OUTPUT[language] not in source:
                issues.append(f"missing null guard in {path.relative_to(ROOT)}")
            if language == "elisa" and any(token in source for token in ("UnsafePointer", "*i64", "*u8")):
                issues.append("Elisa source uses raw pointer storage")
    try:
        workload = json.loads((package / "workload.json").read_text(encoding="utf-8"))
        if not isinstance(workload, dict) or any(
                not isinstance(workload.get(key), dict)
                for key in ("input", "output", "workspace", "measurement")):
            return issues + ["workload root and metadata sections must be objects"]
        if (workload.get("algorithm") != "newton_compositional_inverse_fps"
                or workload.get("function_symbol") != "newton_compositional_inverse_fps"
                or workload.get("abi") != "i64_array_bytes_output"
                or workload.get("input", {}).get("maximum_valid_length") != 17
                or workload.get("input", {}).get("maximum_parseable_length") != 18
                or workload.get("output", {}).get("maximum_bytes") != 128
                or workload.get("workspace", {}).get("bytes") != 2176
                or workload.get("measurement", {}).get("comparison_model") != "i64_array_bytes_output_call"):
            issues.append("workload metadata differs from the Newton reversion contract")
        cases = workload.get("cases")
        if not isinstance(cases, list):
            issues.append("workload cases must be an array")
        else:
            seen = set()
            for case in cases:
                if not isinstance(case, dict) or not isinstance(case.get("id"), str):
                    issues.append("invalid workload case")
                    continue
                case_id = case["id"]
                if case_id in seen:
                    issues.append(f"repeated case ID: {case_id}")
                seen.add(case_id)
                values, length = case.get("input_values"), case.get("input_length")
                if not isinstance(values, list) or type(length) is not int or length != len(values):
                    issues.append(f"invalid case framing: {case_id}")
                    continue
                arguments = (values, case.get("output_capacity"), case.get("output_is_null", False),
                             case.get("input_is_null", False), length)
                expected = (case.get("expected_result"), case.get("expected_output_hex"))
                for name, oracle in (("primary", primary_output), ("reference", independent_output)):
                    result, output = oracle(*arguments)
                    if (result, output.hex()) != expected:
                        issues.append(f"{name} oracle disagrees with fixture: {case_id}")
            required = {"identity", "quadratic", "nonzero-constant", "zero-linear",
                        "invalid-before-null-output", "coefficient-out-of-range", "short-buffer",
                        "null-output", "null-input"}
            if not required <= seen:
                issues.append("missing required cases: " + ", ".join(sorted(required - seen)))
    except (OSError, json.JSONDecodeError) as error:
        issues.append(f"invalid workload: {error}")
    return issues
