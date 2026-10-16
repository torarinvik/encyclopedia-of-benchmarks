"""Bounded oracle for the pinned Python harmonic-series predicate."""

from __future__ import annotations

import struct

MAX_VALUES = 32
INVALID_RESULT = -1e300


def _binary64_from_signed_bits(bits: int) -> float:
    unsigned_bits = bits & ((1 << 64) - 1)
    return struct.unpack(">d", unsigned_bits.to_bytes(8, "big"))[0]


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Return 1.0/0.0 for the exact reciprocal-difference predicate.

    Inputs encode ``[count, binary64_bits_as_signed_i64...]``. Empty lists and
    lists containing either signed zero map the source's ValueError to the
    benchmark invalid-result sentinel.
    """
    if (not isinstance(values, (list, tuple)) or not values
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT
    count = values[0]
    if not 1 <= count <= MAX_VALUES or len(values) != count + 1:
        return INVALID_RESULT

    series = [_binary64_from_signed_bits(bits) for bits in values[1:]]
    if any(value == 0.0 for value in series):
        return INVALID_RESULT
    if count == 1:
        return 1.0

    reciprocals = [1.0 / value for value in series]
    common_difference = reciprocals[1] - reciprocals[0]
    for index in range(2, count):
        if reciprocals[index] - reciprocals[index - 1] != common_difference:
            return 0.0
    return 1.0
