"""Independent oracle for the bounded Java EMAFilter recurrence."""

from __future__ import annotations

import struct

I64_MIN = -(2**63)
I64_MAX = 2**63 - 1
MAX_INPUT_LENGTH = 7
MAX_SAMPLE_COUNT = 4
MAX_SAMPLE_VALUE = 1_000_000


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    """Return the output byte count and little-endian binary64 filter trace."""
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    alpha_units, count = values[:2]
    if not 1 <= alpha_units <= 1024 or not 0 <= count <= MAX_SAMPLE_COUNT or len(values) != count + 2:
        return -1, b""
    samples = values[2:]
    if any(not -MAX_SAMPLE_VALUE <= value <= MAX_SAMPLE_VALUE for value in samples):
        return -1, b""
    alpha = alpha_units / 1024.0
    output_values: list[float] = []
    for index, sample in enumerate(samples):
        current = float(sample)
        if index == 0:
            output_values.append(current)
        else:
            previous = output_values[-1]
            output_values.append(alpha * current + (1.0 - alpha) * previous)
    output = b"".join(struct.pack("<d", value) for value in output_values)
    return len(output), output
