"""Normalize the pinned sumset result as sorted newline-delimited ASCII."""

from __future__ import annotations

MAX_INPUT_LENGTH = 130


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    count_a, count_b = values[:2]
    if (not 0 <= count_a <= 64 or not 0 <= count_b <= 64
            or len(values) != 2 + count_a + count_b):
        return -1, b""
    set_a = values[2:2 + count_a]
    set_b = values[2 + count_a:]
    if any(not -1000 <= value <= 1000 for value in (*set_a, *set_b)):
        return -1, b""
    sums = {left + right for left in set_a for right in set_b}
    output = b"".join(f"{value}\n".encode("ascii") for value in sorted(sums))
    return len(output), output
