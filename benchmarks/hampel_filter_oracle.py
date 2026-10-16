"""Bounded oracle for the pinned three-sample Java Hampel filter."""

from __future__ import annotations

import struct

MAX_SAMPLE_COUNT = 128
MAX_INPUT_LENGTH = MAX_SAMPLE_COUNT + 1
MAX_OUTPUT_BYTES = MAX_SAMPLE_COUNT * 8
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY = -2


def _median(values: list[float]) -> float:
    ordered = sorted(values)
    middle = len(ordered) // 2
    if len(ordered) % 2:
        return ordered[middle]
    return 0.5 * (ordered[middle - 1] + ordered[middle])


def expected_output(values: tuple[int, ...] | list[int],
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, (tuple, list)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return INVALID_RESULT, b""
    count, *samples = values
    if (not 0 <= count <= MAX_SAMPLE_COUNT or len(samples) != count
            or any(not -1000 <= value <= 1000 for value in samples)):
        return INVALID_RESULT, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return INVALID_RESULT, b""

    window: list[float] = []
    filtered: list[int] = []
    for sample in samples:
        value = float(sample)
        window.append(value)
        if len(window) > 3:
            window.pop(0)
        center = _median(window)
        mad = _median([abs(item - center) for item in window])
        result = center if abs(value - center) > 3.0 * 1.4826 * mad else value
        filtered.append(int(result))

    output = b"".join(struct.pack("<q", value) for value in filtered)
    if output_capacity is not None and output_capacity < len(output):
        return INSUFFICIENT_CAPACITY, b""
    return len(output), output
