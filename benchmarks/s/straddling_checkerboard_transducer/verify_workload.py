"""Static fixture framing and dual-reference checker; intentionally not run."""

from __future__ import annotations

import json
from pathlib import Path

from . import independent_oracle, primary_oracle

PACKAGE = Path(__file__).resolve().parent
EXPECTED_TIME = "O(text_length) for a fixed 30-cell board, including bounded O(28^2) duplicate-symbol validation."
EXPECTED_SPACE = "O(1) fixed scratch apart from at most 128 bytes of staged output."
ROSETTA_URL = (
    "https://github.com/acmeism/RosettaCodeData/blob/"
    "1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks"
)
CRYPTOTOOL_URL = "https://www.csd.uoc.gr/~hy458/2022/resources/files/CrypTool-Book-en-v12-May18.pdf"


def verify() -> list[str]:
    issues: list[str] = []
    try:
        workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return [f"cannot read workload: {error}"]

    if workload.get("algorithm") != "straddling_checkerboard_transducer":
        issues.append("algorithm name mismatch")
    if workload.get("function_symbol") != workload.get("algorithm"):
        issues.append("function symbol mismatch")
    if workload.get("abi") != "i64_array_bytes_output":
        issues.append("ABI mismatch")
    if workload.get("time_complexity") != EXPECTED_TIME:
        issues.append("time complexity metadata missing or inconsistent")
    if workload.get("space_complexity") != EXPECTED_SPACE:
        issues.append("space complexity metadata missing or inconsistent")
    input_contract = workload.get("input", {})
    output_contract = workload.get("output", {})
    if input_contract.get("maximum_valid_length") != primary_oracle.MAX_VALID_INPUT_LENGTH:
        issues.append("maximum valid input frame mismatch")
    if input_contract.get("maximum_parseable_length") != primary_oracle.MAX_PARSEABLE_INPUT_LENGTH:
        issues.append("maximum parseable input frame mismatch")
    if input_contract.get("text_length_range") != [0, primary_oracle.MAX_TEXT_LENGTH]:
        issues.append("text length range mismatch")
    if output_contract.get("maximum_bytes") != primary_oracle.MAX_OUTPUT_BYTES:
        issues.append("maximum output bound mismatch")
    if workload.get("workspace", {}).get("bytes") != primary_oracle.WORKSPACE_BYTES:
        issues.append("workspace bound mismatch")

    sources = workload.get("sources", [])
    rosetta = [source for source in sources if source.get("url") == ROSETTA_URL]
    book = [source for source in sources if source.get("url") == CRYPTOTOOL_URL]
    if not rosetta or rosetta[0].get("score") != 9 or rosetta[0].get("role") != "title-only discovery":
        issues.append("pinned title-only Rosetta discovery metadata missing")
    if not book or "GNU Free Documentation License 1.3 or later" not in book[0].get("license", ""):
        issues.append("CrypTool method-source/license metadata missing")

    cases = workload.get("cases", [])
    case_by_id = {case.get("id"): case for case in cases if isinstance(case, dict)}
    for case in cases:
        name = case.get("id", "<unnamed>")
        values = case.get("input_values", [])
        length = case.get("input_length")
        if not isinstance(values, list):
            issues.append(f"{name}: input_values must be an array")
            continue
        if type(length) is not int or length != len(values):
            issues.append(f"{name}: input_length does not match input_values")
            continue
        try:
            expected = (
                int(case["expected_result"]),
                bytes.fromhex(case["expected_output_hex"]),
            )
        except (KeyError, TypeError, ValueError) as error:
            issues.append(f"{name}: malformed expected result/output: {error}")
            continue
        output_is_null = case.get("output_is_null", False)
        input_is_null = case.get("input_is_null", False)
        capacity = case.get("output_capacity")
        primary = primary_oracle.expected_output(
            values, capacity, output_is_null, input_is_null, length
        )
        independent = independent_oracle.expected_output(
            values, capacity, output_is_null, input_is_null, length
        )
        if primary != expected:
            issues.append(f"{name}: primary reference disagrees with fixture")
        if independent != expected:
            issues.append(f"{name}: independent reference disagrees with fixture")
        if primary != independent:
            issues.append(f"{name}: references disagree")
        if expected[0] < 0 and expected[1]:
            issues.append(f"{name}: error result must not carry output bytes")
        if len(expected[1]) > primary_oracle.MAX_OUTPUT_BYTES:
            issues.append(f"{name}: expected output exceeds declared bound")

    if not cases:
        issues.append("workload has no cases")
    nul_case = case_by_id.get("invalid-nul-encode-hole-is-not-a-symbol", {})
    if nul_case.get("expected_result") != -1:
        issues.append("NUL hole/symbol rejection fixture missing")
    maximum = case_by_id.get("maximum-128-byte-lower-row-encoding", {})
    if (maximum.get("input_length") != 96 or maximum.get("expected_result") != 128
            or maximum.get("output_capacity") != 128
            or len(maximum.get("input_values", [])) != 96):
        issues.append("64-symbol maximum-output fixture missing or malformed")
    short = case_by_id.get("maximum-output-capacity-127-fails", {})
    if short.get("output_capacity") != 127 or short.get("expected_result") != -2:
        issues.append("127-byte output-capacity failure fixture missing")
    return issues
