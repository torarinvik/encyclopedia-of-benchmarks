"""Oracle for the first generator found by the bounded primitive-root search."""

from __future__ import annotations

MAX_MODULUS = 127
MAX_INPUT_LENGTH = 2


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) != 1
            or type(values[0]) is not int or not -(1 << 63) <= values[0] < (1 << 63)
            or not 2 <= values[0] <= MAX_MODULUS):
        return -1
    modulus = values[0]
    for candidate in range(1, modulus):
        powers = {pow(candidate, exponent, modulus) for exponent in range(modulus - 1)}
        if len(powers) == modulus - 1:
            return candidate
    return 0
