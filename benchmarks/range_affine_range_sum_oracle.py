"""Direct array oracle for the bounded modular affine range-sum profile."""

from __future__ import annotations

from collections.abc import Sequence

MODULUS = 998_244_353
MAX_LENGTH = 64
MAX_OPERATIONS = 64
MAX_VALID_INPUT_VALUES = 386
MAX_PARSEABLE_INPUT_VALUES = 387
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int] | None) -> int:
    """Return the query checksum, or -1 for a malformed operation trace."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_PARSEABLE_INPUT_VALUES
        or len(values) < 2
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT

    n = values[0]
    if not 1 <= n <= MAX_LENGTH or len(values) < n + 2:
        return INVALID_RESULT
    data = list(values[1 : n + 1])
    if any(not 0 <= value < MODULUS for value in data):
        return INVALID_RESULT
    q = values[n + 1]
    if not 1 <= q <= MAX_OPERATIONS:
        return INVALID_RESULT

    cursor = n + 2
    checksum = 0
    for operation_index in range(q):
        if cursor >= len(values):
            return INVALID_RESULT
        opcode = values[cursor]
        if opcode == 0:
            if cursor + 5 > len(values):
                return INVALID_RESULT
            left, right, multiplier, offset = values[cursor + 1 : cursor + 5]
            cursor += 5
            if not 0 <= left < right <= n:
                return INVALID_RESULT
            if not (1 <= multiplier < MODULUS and 0 <= offset < MODULUS):
                return INVALID_RESULT
            for index in range(left, right):
                data[index] = (multiplier * data[index] + offset) % MODULUS
        elif opcode == 1:
            if cursor + 3 > len(values):
                return INVALID_RESULT
            left, right = values[cursor + 1 : cursor + 3]
            cursor += 3
            if not 0 <= left < right <= n:
                return INVALID_RESULT
            result = sum(data[left:right]) % MODULUS
            checksum += (operation_index + 1) * (result + MODULUS)
        else:
            return INVALID_RESULT

    if cursor != len(values):
        return INVALID_RESULT
    return checksum
