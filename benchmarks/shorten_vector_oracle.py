"""Oracle for R's suffix-key vector shortening operation."""

from __future__ import annotations

import struct

MAX_LENGTH = 64
MAX_INPUT_LENGTH = 2 + MAX_LENGTH + 1  # admit one over-bound length
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH
MAX_OUTPUT_BYTES = (MAX_LENGTH - 1) * 8
MIN_VALUE = -1_000_000
MAX_VALUE = 1_000_000
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(values: tuple[int, ...] | list[int],
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    """Return bytes written and stable little-endian i64 output bytes."""
    if (not isinstance(values, (tuple, list)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return INVALID_RESULT, b""

    length, by = values[:2]
    if not 0 <= length <= MAX_LENGTH or not 0 <= by <= length:
        return INVALID_RESULT, b""
    if len(values) != 2 + length:
        return INVALID_RESULT, b""

    vector = values[2:]
    if any(not MIN_VALUE <= value <= MAX_VALUE for value in vector):
        return INVALID_RESULT, b""

    if by == 0:
        survivors: list[int] = []
    else:
        keys = set(vector[length - by:])
        survivors = [value for value in vector if value not in keys]

    if output_capacity is not None:
        if type(output_capacity) is not int or output_capacity < 0:
            return INVALID_RESULT, b""
        if output_capacity < len(survivors) * 8:
            return OUTPUT_ERROR, b""

    output = b"".join(struct.pack("<q", value) for value in survivors)
    return len(output), output
