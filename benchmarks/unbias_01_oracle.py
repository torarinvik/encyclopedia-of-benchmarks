"""Oracle for the bounded Von Neumann unbiased-bit extractor."""

from __future__ import annotations

MAX_BIT_COUNT = 256
MAX_INPUT_LENGTH = MAX_BIT_COUNT + 1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1
    count = values[0]
    bits = values[1:]
    if not 0 <= count <= MAX_BIT_COUNT or len(bits) != count or any(bit not in (0, 1) for bit in bits):
        return -1
    for index in range(0, count - 1, 2):
        first, second = bits[index], bits[index + 1]
        if first != second:
            return first
    return -1
