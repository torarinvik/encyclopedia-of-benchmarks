"""Static package and dual-oracle checks; this never launches benchmark ports."""

from __future__ import annotations

import json
from pathlib import Path
import sys

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parents[2]
sys.path.insert(0, str(ROOT / "benchmarks"))
import addition_of_big_integers_oracle as primary  # noqa: E402
import addition_of_big_integers_verifier_oracle as independent  # noqa: E402

PORTS = {
    "c": ROOT / "c/a/addition_of_big_integers.c",
    "c3": ROOT / "c3/a/addition_of_big_integers.c3",
    "cpp": ROOT / "cpp/a/addition_of_big_integers.cpp",
    "elisa": ROOT / "elisa/a/addition_of_big_integers.elisa",
    "mojo": ROOT / "mojo/a/addition_of_big_integers.mojo",
    "nim": ROOT / "nim/a/addition_of_big_integers.nim",
    "odin": ROOT / "odin/a/addition_of_big_integers.odin",
    "rust": ROOT / "rust/a/addition_of_big_integers.rs",
    "v": ROOT / "v/a/addition_of_big_integers.v",
    "zig": ROOT / "zig/a/addition_of_big_integers.zig",
}
SOURCE_URL = (
    "https://github.com/yosupo06/library-checker-problems/blob/master/"
    "big_integer/addition_of_big_integers/task.md"
)


def verify_workload() -> int:
    workload = json.loads((PACKAGE / "workload.json").read_text(encoding="utf-8"))
    if (workload.get("algorithm") != "addition_of_big_integers"
            or workload.get("function_symbol") != "addition_of_big_integers"
            or workload.get("abi") != "i64_array_bytes_output"
            or workload.get("source", {}).get("task_url") != SOURCE_URL):
        raise ValueError("workload identity, ABI, or source attribution is incomplete")
    input_spec = workload.get("input", {})
    output_spec = workload.get("output", {})
    if (input_spec.get("maximum_input_length") != primary.MAX_INPUT_LENGTH
            or input_spec.get("operand_digit_count_range") != [1, primary.MAX_DIGITS]
            or output_spec.get("maximum_output_length") != primary.MAX_OUTPUT_BYTES):
        raise ValueError("workload bounds differ from the primary oracle")

    readme = (PACKAGE / "README.md").read_text(encoding="utf-8")
    rights = (PACKAGE / "RIGHTS.md").read_text(encoding="utf-8")
    if (SOURCE_URL not in readme or "magnitude comparison" not in readme
            or "clean-room" not in readme or "No upstream source code" not in rights):
        raise ValueError("README or rights note omits algorithm distinction or provenance")
    if len(PORTS) != 10:
        raise ValueError("the static inventory must list all ten supported languages")
    for language, path in PORTS.items():
        relative = path.relative_to(ROOT).as_posix()
        if not path.is_file():
            raise ValueError(f"missing {language} port: {relative}")
        text = path.read_text(encoding="utf-8")
        if "addition_of_big_integers" not in text or relative not in readme:
            raise ValueError(f"port symbol or README link missing: {relative}")

    if not primary.__file__ or not independent.__file__:
        raise ValueError("both oracle modules must be importable")
    if primary.__file__ == independent.__file__:
        raise ValueError("primary and independent oracles must be separate files")
    cases = workload.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("workload must contain named fixtures")
    required = {
        "positive-addition", "carry-chain", "negative-operands",
        "opposite-sign-borrow", "negative-result", "opposite-sign-cancellation",
        "maximum-width-cancellation", "leading-zero-invalid", "negative-zero-invalid",
        "plus-sign-invalid", "short-output-capacity", "null-input", "null-output",
        "packed-length-mismatch",
    }
    found: set[str] = set()
    for case in cases:
        if not isinstance(case, dict) or not isinstance(case.get("id"), str):
            raise ValueError("fixture must have a string ID")
        case_id = case["id"]
        if case_id in found:
            raise ValueError(f"duplicate fixture ID: {case_id}")
        found.add(case_id)
        values = case.get("input_values")
        options = {
            "input_length": case.get("input_length"),
            "input_is_null": case.get("input_is_null", False),
            "output_capacity": case.get("output_capacity"),
            "output_is_null": case.get("output_is_null", False),
        }
        if not isinstance(values, list) or case.get("input_length") != len(values):
            raise ValueError(f"fixture length mismatch: {case_id}")
        first_status, first_bytes = primary.expected_output(values, **options)
        second_status, second_bytes = independent.expected_output(values, **options)
        expected_hex = case.get("expected_output_hex")
        if first_status != second_status or first_status != case.get("expected_result"):
            raise ValueError(f"oracle status mismatch: {case_id}")
        if first_bytes != second_bytes:
            raise ValueError(f"independent oracle disagreement: {case_id}")
        if first_bytes.hex() != expected_hex:
            raise ValueError(f"fixture bytes differ from both oracles: {case_id}")
        if first_status >= 0 and first_status != len(first_bytes):
            raise ValueError(f"successful output length mismatch: {case_id}")
        if first_status < 0 and first_bytes:
            raise ValueError(f"error fixture must have empty output: {case_id}")
    if not required.issubset(found):
        raise ValueError(f"missing fixtures: {sorted(required - found)}")
    if not (PACKAGE / "README.md").is_file() or not (PACKAGE / "RIGHTS.md").is_file():
        raise ValueError("documentation or provenance file is missing")
    return len(cases)


if __name__ == "__main__":
    print(f"statically reviewed {verify_workload()} fixtures and {len(PORTS)} ports")
