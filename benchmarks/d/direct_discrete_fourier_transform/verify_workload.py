"""Static workload and dual-reference reconciliation."""
import json
import math
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
from d.direct_discrete_fourier_transform.primary_oracle import (  # noqa: E402
    ABSOLUTE_TOLERANCE, MAX_OUTPUT_ELEMENTS, MAX_PARSEABLE_INPUT_LENGTH,
    MAX_VALID_INPUT_LENGTH, RELATIVE_TOLERANCE, WORKSPACE_ELEMENTS,
    expected_output,
)
from d.direct_discrete_fourier_transform.independent_oracle import (  # noqa: E402
    expected_output as independent_output,
)

SOURCE_URL = "https://www.algorithm-archive.org/contents/cooley_tukey/cooley_tukey.html"


def _close(left, right):
    return (isinstance(left, list) and isinstance(right, list)
            and len(left) == len(right)
            and all(math.isclose(float(a), float(b),
                                 rel_tol=RELATIVE_TOLERANCE,
                                 abs_tol=ABSOLUTE_TOLERANCE)
                    for a, b in zip(left, right)))


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("algorithm") != "direct_discrete_fourier_transform"
            or workload.get("function_symbol") != "direct_discrete_fourier_transform"
            or workload.get("abi") != "float64_slice_io"
            or workload.get("source", {}).get("url") != SOURCE_URL
            or workload.get("input", {}).get("maximum_valid_length") != MAX_VALID_INPUT_LENGTH
            or workload.get("input", {}).get("maximum_parseable_length") != MAX_PARSEABLE_INPUT_LENGTH
            or workload.get("output", {}).get("maximum_elements") != MAX_OUTPUT_ELEMENTS
            or workload.get("workspace", {}).get("elements") != WORKSPACE_ELEMENTS
            or workload.get("output", {}).get("absolute_tolerance") != ABSOLUTE_TOLERANCE
            or workload.get("output", {}).get("relative_tolerance") != RELATIVE_TOLERANCE):
        raise ValueError("workload identity or declared bounds differ from the oracle")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain cases")
    ids = set()
    saw_max = saw_trailing = False
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            raise ValueError("fixture needs a string ID")
        if case["id"] in ids:
            raise ValueError(f"duplicate fixture ID: {case['id']}")
        ids.add(case["id"])
        values = case.get("input_values")
        if not isinstance(values, list):
            raise ValueError(f"fixture input is not a list: {case['id']}")
        if not case.get("input_is_null", False) and case.get("input_length") != len(values):
            raise ValueError(f"fixture input length mismatch: {case['id']}")
        kwargs = {
            "output_capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
            "input_is_null": case.get("input_is_null", False),
            "input_length": case.get("input_length"),
        }
        primary = expected_output(values, **kwargs)
        other = independent_output(values, **kwargs)
        expected = case.get("expected_output")
        if primary[0] != case.get("expected_result") or not _close(primary[1], expected):
            raise ValueError(f"primary fixture mismatch: {case['id']}")
        if other[0] != primary[0] or not _close(other[1], primary[1]):
            raise ValueError(f"independent reference mismatch: {case['id']}")
        if case["id"] == "maximum_n64_constant":
            saw_max = (case.get("input_length") == MAX_VALID_INPUT_LENGTH
                       and case.get("expected_result") == MAX_OUTPUT_ELEMENTS)
        if case["id"] == "max_parseable_trailing_word":
            saw_trailing = case.get("input_length") == MAX_PARSEABLE_INPUT_LENGTH and primary[0] == -1
    if not saw_max or not saw_trailing:
        raise ValueError("workload must cover maximum output and maximum parseable trailing word")
    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if SOURCE_URL not in readme or "clean-room" not in rights:
        raise ValueError("provenance or rights note missing")
    return len(cases)


if __name__ == "__main__":
    print(f"checked {verify_workload()} fixtures")

