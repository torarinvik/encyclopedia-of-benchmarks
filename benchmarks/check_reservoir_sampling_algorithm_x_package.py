"""Static inventory and fixture preflight for quantized Algorithm X."""

from pathlib import Path

from workload_json import load_workload
from x.reservoir_sampling_algorithm_x.primary_oracle import expected_output as primary
from x.reservoir_sampling_algorithm_x.independent_oracle import expected_output as independent

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "benchmarks/x/reservoir_sampling_algorithm_x"
NAME = "reservoir_sampling_algorithm_x"
EXTENSIONS = {"c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa", "mojo": "mojo",
              "nim": "nim", "odin": "odin", "rust": "rs", "v": "v", "zig": "zig"}


def static_issues(workload=None):
    if workload is None:
        try:
            workload = load_workload(PACKAGE / "workload.json")
        except (OSError, ValueError) as error:
            return [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    issues = []
    spec, output = workload.get("input"), workload.get("output")
    if (workload.get("algorithm") != NAME or workload.get("function_symbol") != NAME
            or workload.get("abi") != "i64_array_bytes_output" or not isinstance(spec, dict)
            or spec.get("maximum_valid_length") != 48 or spec.get("maximum_parseable_length") != 49
            or not isinstance(output, dict) or output.get("maximum_bytes") != 64
            or output.get("output_untouched_on_error") is not True
            or workload.get("workspace", {}).get("bytes") != 64):
        issues.append("identity or bounds mismatch")
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "x" / f"{NAME}.{extension}"
        if not path.is_file() or NAME not in path.read_text(encoding="utf-8"):
            issues.append(f"missing port or symbol: {language}")
    for filename in ("README.md", "RIGHTS.md", "INVENTORY.md", "primary_oracle.py", "independent_oracle.py", "check_inventory.py"):
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package file: {filename}")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["missing cases"]
    seen = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            issues.append("invalid case")
            continue
        case_id = case["id"]
        if case_id in seen:
            issues.append(f"duplicate case: {case_id}")
        seen.add(case_id)
        values = case.get("input_values")
        length = case.get("input_length")
        capacity = case.get("output_capacity")
        null_in = case.get("input_is_null", False)
        null_out = case.get("output_is_null", False)
        if (not isinstance(values, list) or type(length) is not int or type(capacity) is not int
                or capacity < 0 or type(null_in) is not bool or type(null_out) is not bool
                or (null_in and (values or length != 0))
                or (not null_in and (length != len(values) or length > 49))):
            issues.append(f"invalid framing: {case_id}")
            continue
        try:
            expected = (case["expected_result"], bytes.fromhex(case["expected_output_hex"]))
        except (KeyError, TypeError, ValueError):
            issues.append(f"invalid expected output: {case_id}")
            continue
        args = (values, capacity, null_out, null_in, length)
        if type(expected[0]) is not int or primary(*args) != expected or independent(*args) != expected:
            issues.append(f"reference disagreement: {case_id}")
    required = {
        "consecutive-replacements", "skip-one-record", "terminal-skip-retains-reservoir",
        "initial-reservoir-is-whole-stream", "single-slot-draw", "maximum-output",
        "maximum-valid-frame", "maximum-parseable-trailing-word", "invalid-draw-range",
        "invalid-before-null-output", "invalid-non-power-of-two-sample", "invalid-value", "wrong-frame-length",
        "short-output", "null-output", "null-input",
    }
    if not required <= seen:
        issues.append("missing required cases")
    return issues
