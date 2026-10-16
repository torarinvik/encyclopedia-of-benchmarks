"""Reference model for the pinned Python rounded data transformations."""

from __future__ import annotations

import struct
from statistics import mean, stdev

INVALID_RESULT = -1
MAX_SAMPLE_COUNT = 128
MAX_INPUT_LENGTH = MAX_SAMPLE_COUNT + 2
MAX_OUTPUT_BYTES = MAX_SAMPLE_COUNT * 8
MIN_VALUE = -100_000
MAX_VALUE = 100_000
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    """Apply source normalization (mode 0) or standardization (mode 1)."""
    if (not isinstance(values, (list, tuple))
            or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""
    mode, count = values[:2]
    data = values[2:]
    if (mode not in (0, 1) or not 2 <= count <= MAX_SAMPLE_COUNT
            or len(data) != count
            or any(not MIN_VALUE <= value <= MAX_VALUE for value in data)):
        return INVALID_RESULT, b""
    if min(data) == max(data):
        return INVALID_RESULT, b""
    if mode == 0:
        low, high = min(data), max(data)
        transformed = [round((value - low) / (high - low), 3) for value in data]
    else:
        average = mean(data)
        deviation = stdev(data)
        transformed = [round((value - average) / deviation, 3) for value in data]
    return len(transformed) * 8, struct.pack("<" + "d" * len(transformed), *transformed)
