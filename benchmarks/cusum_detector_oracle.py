"""Bounded Java CUSUM detector oracle with little-endian i64 signals."""

from __future__ import annotations

import struct

MAX_SAMPLE_COUNT = 128
MAX_INPUT_LENGTH = 5 + MAX_SAMPLE_COUNT
MAX_OUTPUT_BYTES = MAX_SAMPLE_COUNT * 8


def expected_output(values: tuple[int, ...] | list[int],
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    """Return status and source-ordered signal codes for a packed stream."""
    if (not isinstance(values, (tuple, list)) or not 5 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""

    count, target, sigma, allowance, threshold = values[:5]
    samples = values[5:]
    if (not 0 <= count <= MAX_SAMPLE_COUNT or len(samples) != count
            or not -1000 <= target <= 1000
            or not 1 <= sigma <= 1000
            or not 0 <= allowance <= 1000
            or not 1 <= threshold <= 1000
            or any(not -1000 <= sample <= 1000 for sample in samples)):
        return -1, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""

    upper = 0.0
    lower = 0.0
    signals: list[int] = []
    for sample in samples:
        z = (sample - target) / sigma
        upper = max(0.0, upper + z - allowance)
        lower = max(0.0, lower - z - allowance)
        if upper > threshold:
            signals.append(1)
            upper = lower = 0.0
        elif lower > threshold:
            signals.append(-1)
            upper = lower = 0.0
        else:
            signals.append(0)

    output = b"".join(struct.pack("<q", signal) for signal in signals)
    if output_capacity is not None and output_capacity < len(output):
        return -2, b""
    return len(output), output
