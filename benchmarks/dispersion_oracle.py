"""Reference model for bounded population variance and standard deviation."""

from __future__ import annotations

import math
import struct

INVALID_RESULT = -1
MAX_INPUT_LENGTH = 128
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MIN_VALUE = -10_000
MAX_VALUE = 10_000
OUTPUT_BYTES = 16
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    """Return population variance and standard deviation as little-endian f64s."""
    if (not isinstance(values, (list, tuple))
            or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
            or any(not MIN_VALUE <= value <= MAX_VALUE for value in values)):
        return INVALID_RESULT, b""

    mean = sum(values) / len(values)
    variance = sum((value - mean) ** 2 for value in values) / len(values)
    standard_deviation = math.sqrt(variance)
    return OUTPUT_BYTES, struct.pack("<dd", variance, standard_deviation)
