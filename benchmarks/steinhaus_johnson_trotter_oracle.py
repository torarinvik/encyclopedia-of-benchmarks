"""Bounded oracle for the pinned Steinhaus–Johnson–Trotter implementation."""

from __future__ import annotations

import math
import struct
from collections.abc import Sequence

MIN_LENGTH = 1
MAX_LENGTH = 6
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
MAX_PARSEABLE_INPUT_LENGTH = MAX_LENGTH + 1
MAX_OUTPUT_BYTES = 4 * math.factorial(MAX_LENGTH) * MAX_LENGTH
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _permutations(values: Sequence[int]) -> list[list[int]]:
    current = list(values)
    inversion = [0] * len(current)
    result = [current.copy()]
    index = 1
    while index < len(current):
        if inversion[index] < index:
            if index % 2 == 0:
                current[0], current[index] = current[index], current[0]
            else:
                swap_index = inversion[index]
                current[swap_index], current[index] = current[index], current[swap_index]
            result.append(current.copy())
            inversion[index] += 1
            index = 1
        else:
            inversion[index] = 0
            index += 1
    return result


def expected_output(
    values: Sequence[int],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return the flattened little-endian i32 permutation rows or an ABI sentinel."""
    if type(input_is_null) is not bool or type(output_is_null) is not bool:
        return INVALID_RESULT, b""
    if input_is_null:
        return INVALID_RESULT, b""
    if (
        not isinstance(values, (list, tuple))
        or not MIN_LENGTH <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I32_MIN <= value <= I32_MAX for value in values)
        or not MIN_LENGTH <= len(values) <= MAX_LENGTH
    ):
        return INVALID_RESULT, b""
    if type(output_capacity) is not int or output_capacity < 0:
        return INVALID_RESULT, b""

    permutation_count = math.factorial(len(values))
    required_bytes = 4 * permutation_count * len(values)
    if output_is_null or output_capacity < required_bytes:
        return OUTPUT_ERROR_RESULT, b""

    rows = _permutations(values)
    output = b"".join(struct.pack("<" + "i" * len(values), *row) for row in rows)
    return len(output), output
