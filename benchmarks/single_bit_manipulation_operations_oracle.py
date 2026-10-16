"""Exact bounded oracle for six single-bit operations from TheAlgorithms/Python."""

from __future__ import annotations

INVALID_RESULT = -1
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1
I32_MIN, I32_MAX = -(1 << 31), (1 << 31) - 1


def expected_result(values: list[int] | tuple[int, ...] | None) -> int:
    if values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if (
        len(values) != 3
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT
    opcode, number, position = values
    if not I32_MIN <= number <= I32_MAX or not 0 <= opcode <= 5:
        return INVALID_RESULT
    if opcode == 5:
        if position != -1:
            return INVALID_RESULT
        return number & (number - 1)
    if not 0 <= position <= 31:
        return INVALID_RESULT
    mask = 1 << position
    if opcode == 0:
        return number | mask
    if opcode == 1:
        return number & ~mask
    if opcode == 2:
        return number ^ mask
    if opcode == 3:
        return int(((number >> position) & 1) == 1)
    return int((number & mask) != 0)
