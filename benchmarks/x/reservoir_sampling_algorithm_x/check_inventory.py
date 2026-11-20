"""Package-local, non-executing inventory checks for Algorithm X."""

from pathlib import Path

from .primary_oracle import expected_output as primary
from .independent_oracle import expected_output as independent

PACKAGE = Path(__file__).resolve().parent
REPOSITORY = PACKAGE.parents[2]
ALGORITHM = "reservoir_sampling_algorithm_x"
PORTS = {
    "c": "c",
    "c3": "c3",
    "cpp": "cpp",
    "elisa": "elisa",
    "mojo": "mojo",
    "nim": "nim",
    "odin": "odin",
    "rust": "rs",
    "v": "v",
    "zig": "zig",
}


def inspect_inventory():
    """Return missing artifact or language-port descriptions without running code."""
    issues = []
    for filename in (
        "README.md",
        "RIGHTS.md",
        "INVENTORY.md",
        "workload.json",
        "primary_oracle.py",
        "independent_oracle.py",
    ):
        if not (PACKAGE / filename).is_file():
            issues.append(f"missing package artifact: {filename}")
    if not (REPOSITORY / "benchmarks/check_reservoir_sampling_algorithm_x_package.py").is_file():
        issues.append("missing repository package preflight")
    for language, extension in PORTS.items():
        path = REPOSITORY / language / "x" / f"{ALGORITHM}.{extension}"
        if not path.is_file():
            issues.append(f"missing language port: {language}")
    return issues


def static_issues(workload=None):
    """Check inventory metadata and fixture/reference agreement statically."""
    issues = inspect_inventory()
    if workload is None:
        try:
            import json

            workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
        except (OSError, ValueError) as error:
            return issues + [f"cannot read workload: {error}"]
    if not isinstance(workload, dict):
        return issues + ["workload must be an object"]
    input_spec = workload.get("input")
    output_spec = workload.get("output")
    if (workload.get("algorithm") != ALGORITHM
            or workload.get("function_symbol") != ALGORITHM
            or workload.get("abi") != "i64_array_bytes_output"
            or not isinstance(input_spec, dict)
            or input_spec.get("maximum_valid_length") != 48
            or input_spec.get("maximum_parseable_length") != 49
            or not isinstance(output_spec, dict)
            or output_spec.get("maximum_bytes") != 64
            or workload.get("workspace", {}).get("bytes") != 64):
        issues.append("workload identity or bounds mismatch")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        return issues + ["workload cases are missing"]
    for case in cases:
        if not isinstance(case, dict):
            issues.append("invalid workload case")
            continue
        values = case.get("input_values")
        length = case.get("input_length")
        capacity = case.get("output_capacity")
        if (not isinstance(values, list) or type(length) is not int
                or type(capacity) is not int or capacity < 0):
            issues.append(f"invalid framing: {case.get('id', '<unnamed>')}")
            continue
        try:
            expected = (
                case["expected_result"],
                bytes.fromhex(case["expected_output_hex"]),
            )
        except (KeyError, TypeError, ValueError):
            issues.append(f"invalid expected output: {case.get('id', '<unnamed>')}")
            continue
        args = (
            values,
            capacity,
            case.get("output_is_null", False),
            case.get("input_is_null", False),
            length,
        )
        if primary(*args) != expected or independent(*args) != expected:
            issues.append(f"reference disagreement: {case.get('id', '<unnamed>')}")
    return issues
