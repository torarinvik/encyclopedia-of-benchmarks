"""Independent oracle for the bounded count_homogenous byte-array benchmark."""

from __future__ import annotations

I64_MIN = -(2**63)
I64_MAX = 2**63 - 1
MAX_TEXT_BYTES = 4096
MAX_INPUT_LENGTH = MAX_TEXT_BYTES + 2  # include one oversized invalid payload


def expected_result(values: list[int]) -> int:
    """Count contiguous equal-byte runs, or return -1 for malformed input."""
    if (not isinstance(values, list) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1
    count = values[0]
    if not 0 <= count <= MAX_TEXT_BYTES or len(values) != count + 1:
        return -1
    text = values[1:]
    if any(not 0 <= byte <= 127 for byte in text):
        return -1
    if count == 0:
        return 0
    return 1 + sum(text[index] != text[index - 1] for index in range(1, count))
