"""Static inventory and oracle-agreement checks; intentionally not executed."""

from pathlib import Path

from workload_json import load_workload
from l.linear_hashing_trace.primary_oracle import expected_result as primary
from l.linear_hashing_trace.independent_oracle import expected_result as independent

ROOT = Path(__file__).resolve().parents[3]
PACKAGE = ROOT / "benchmarks/l/linear_hashing_trace"
EXTENSIONS = {"c": "c", "c3": "c3", "cpp": "cpp", "elisa": "elisa",
              "mojo": "mojo", "nim": "nim", "odin": "odin", "rust": "rs",
              "v": "v", "zig": "zig"}


def static_issues(workload=None):
    if workload is None:
        try:
            workload = load_workload(PACKAGE / "workload.json")
        except (OSError, ValueError) as error:
            return [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return ["workload must be an object"]
    inputs = workload.get("input")
    if (workload.get("algorithm") != "linear_hashing_trace"
            or workload.get("function_symbol") != "linear_hashing_trace"
            or workload.get("abi") != "i64_array_scalar"
            or not isinstance(inputs, dict)
            or inputs.get("maximum_valid_length") != 127
            or inputs.get("maximum_parseable_length") != 128
            or inputs.get("maximum_valid_values") != 127
            or inputs.get("maximum_parseable_values") != 128):
        return ["identity or input bounds mismatch"]

    issues = []
    for language, extension in EXTENSIONS.items():
        path = ROOT / language / "l" / f"linear_hashing_trace.{extension}"
        if not path.is_file() or "linear_hashing_trace" not in path.read_text(encoding="utf-8"):
            issues.append(f"missing port or symbol: {language}")
    for name in ("README.md", "RIGHTS.md", "INVENTORY.md", "primary_oracle.py",
                 "independent_oracle.py"):
        if not (PACKAGE / name).is_file():
            issues.append(f"missing package file: {name}")

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
        is_null = case.get("input_is_null", False)
        if (not isinstance(values, list) or type(length) is not int or type(is_null) is not bool
                or (is_null and (values or not 0 <= length <= 128))
                or (not is_null and (length != len(values) or length > 128))):
            issues.append(f"invalid framing: {case_id}")
            continue
        expected = case.get("expected_result")
        if (type(expected) is not int
                or primary(values, is_null, length) != expected
                or independent(values, is_null, length) != expected):
            issues.append(f"oracle disagreement: {case_id}")
    required = {"empty_trace", "insert_duplicate_lookup_and_erase",
                "negative_keys_share_initial_bucket", "successful_inserts_cross_split_threshold",
                "split_rehash_preserves_old_and_new_bucket_members",
                "maximum_trace_reaches_full_directory_round", "unknown_opcode",
                "key_out_of_domain", "extra_trailing_word",
                "maximum_parseable_trailing_word", "declared_length_mismatch", "null_input"}
    if not required <= seen:
        issues.append("missing cases: " + ", ".join(sorted(required - seen)))
    return issues
