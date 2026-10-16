"""Portable ASCII oracle for the bounded P-series benchmark."""

from __future__ import annotations

I64_MIN, I64_MAX = -(2**63), 2**63 - 1
MAX_INPUT_LENGTH = 3  # two valid values plus one extra item for malformed input
MAX_TERMS = 256
MAX_POWER = 7
MAX_OUTPUT_BYTES = 4953


def expected_output(values: list[int]) -> tuple[int, bytes]:
    """Return the source-formatted series bytes, or -1 for malformed input."""
    if (not isinstance(values, list) or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    if len(values) != 2:
        return -1, b""
    nth_term, power = values
    if not -MAX_TERMS <= nth_term <= MAX_TERMS or not 0 <= power <= MAX_POWER:
        return -1, b""
    if nth_term <= 0:
        return 0, b""

    lines = ["1"]
    lines.extend(f"1 / {term**power}" for term in range(2, nth_term + 1))
    output = ("\n".join(lines) + "\n").encode("ascii")
    return len(output), output
