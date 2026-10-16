"""Set-based oracle for intersection of two sorted arrays."""

from __future__ import annotations

import struct

MAX_ARRAY_LENGTH = 64
MAX_INPUT_LENGTH = 2 * (MAX_ARRAY_LENGTH + 1)
MAX_OUTPUT_BYTES = MAX_ARRAY_LENGTH * 4
I64_MIN = -(2**63)
I64_MAX = 2**63 - 1
I32_MIN = -(2**31)
I32_MAX = 2**31 - 1


def expected_output(values: tuple[int, ...] | list[int],
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, (tuple, list)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    first_length = values[0]
    if not 0 <= first_length <= MAX_ARRAY_LENGTH:
        return -1, b""
    second_length_position = 1 + first_length
    if second_length_position >= len(values):
        return -1, b""
    second_length = values[second_length_position]
    if not 0 <= second_length <= MAX_ARRAY_LENGTH:
        return -1, b""
    second_start = second_length_position + 1
    if second_start + second_length != len(values):
        return -1, b""
    first = values[1:second_length_position]
    second = values[second_start:]
    if (any(value < I32_MIN or value > I32_MAX for value in first + second)
            or any(left > right for left, right in zip(first, first[1:]))
            or any(left > right for left, right in zip(second, second[1:]))):
        return -1, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""

    common = sorted(set(first).intersection(second))
    output = b"".join(struct.pack("<i", value) for value in common)
    maximum_result_bytes = min(first_length, second_length) * 4
    if output_capacity is not None and output_capacity < maximum_result_bytes:
        return -2, b""
    return len(common), output
