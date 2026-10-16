"""Reference model for bounded min-max normalization and sample standardization."""

from __future__ import annotations

import math
import struct

INVALID_RESULT = -1
MAX_SAMPLE_COUNT = 128
MAX_INPUT_LENGTH = MAX_SAMPLE_COUNT + 2
MAX_OUTPUT_BYTES = MAX_SAMPLE_COUNT * 8
MIN_VALUE = -100_000
MAX_VALUE = 100_000
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    """Apply one source routine; mode 0 is min-max and mode 1 is z-score."""
    if (not isinstance(values, (list, tuple))
            or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""

    mode, count = values[:2]
    sample = values[2:]
    if (mode not in (0, 1) or not 2 <= count <= MAX_SAMPLE_COUNT
            or len(sample) != count
            or any(not MIN_VALUE <= value <= MAX_VALUE for value in sample)):
        return INVALID_RESULT, b""

    minimum = min(sample)
    maximum = max(sample)
    if minimum == maximum:
        return INVALID_RESULT, b""

    if mode == 0:
        span = maximum - minimum
        transformed = [(value - minimum) / span for value in sample]
    else:
        mean = sum(sample) / count
        squared_deviations = sum((value - mean) ** 2 for value in sample)
        sample_deviation = math.sqrt(squared_deviations / (count - 1))
        transformed = [(value - mean) / sample_deviation for value in sample]

    return len(transformed) * 8, struct.pack("<" + "d" * len(transformed), *transformed)
