"""Independent oracle for the bounded Java linear-convolution benchmark."""

from __future__ import annotations

import struct


MAX_SIGNAL_LENGTH = 64
MAX_INPUT_LENGTH = 2 + 2 * MAX_SIGNAL_LENGTH
MAX_OUTPUT_BYTES = (2 * MAX_SIGNAL_LENGTH - 1) * 8


def expected_output(values: tuple[int, ...] | list[int],
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    """Return status and little-endian i64 coefficients for packed signals."""
    if (not isinstance(values, (tuple, list)) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""

    a_count, b_count = values[:2]
    if (not 1 <= a_count <= MAX_SIGNAL_LENGTH or not 1 <= b_count <= MAX_SIGNAL_LENGTH
            or len(values) != 2 + a_count + b_count):
        return -1, b""
    a_values = values[2:2 + a_count]
    b_values = values[2 + a_count:]
    if any(not -1_000_000 <= sample <= 1_000_000 for sample in (*a_values, *b_values)):
        return -1, b""

    result_count = a_count + b_count - 1
    if output_capacity is not None:
        if type(output_capacity) is not int or output_capacity < 0:
            return -1, b""
        if output_capacity < result_count * 8:
            return -2, b""

    coefficients: list[int] = []
    for index in range(result_count):
        first = max(0, index - b_count + 1)
        last = min(index, a_count - 1)
        coefficients.append(sum(a_values[k] * b_values[index - k]
                                for k in range(first, last + 1)))
    output = b"".join(struct.pack("<q", coefficient) for coefficient in coefficients)
    return len(output), output
