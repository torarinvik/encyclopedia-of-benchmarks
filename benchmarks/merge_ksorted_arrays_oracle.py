"""Independent min-heap oracle for the pinned Java k-way array merge."""

from __future__ import annotations

import heapq

MAX_ARRAYS = 16
MAX_TOTAL_VALUES = 128
MIN_VALUE = -1_000_000
MAX_VALUE = 1_000_000
MAX_INPUT_LENGTH = 1 + MAX_ARRAYS + MAX_TOTAL_VALUES
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
INVALID_RESULT = -1
CHECKSUM_OFFSET = 1_000_001


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return INVALID_RESULT
    array_count = values[0]
    if not 1 <= array_count <= MAX_ARRAYS:
        return INVALID_RESULT

    arrays: list[list[int]] = []
    position = 1
    total_values = 0
    for _ in range(array_count):
        if position >= len(values):
            return INVALID_RESULT
        length = values[position]
        position += 1
        if length < 0 or length > MAX_TOTAL_VALUES - total_values:
            return INVALID_RESULT
        if length > len(values) - position:
            return INVALID_RESULT
        array = values[position:position + length]
        if (any(not MIN_VALUE <= value <= MAX_VALUE for value in array)
                or any(array[index - 1] > array[index] for index in range(1, length))):
            return INVALID_RESULT
        arrays.append(array)
        position += length
        total_values += length
    if position != len(values):
        return INVALID_RESULT

    heap = [(array[0], array_index, 0)
            for array_index, array in enumerate(arrays) if array]
    heapq.heapify(heap)
    checksum = 0
    merged_index = 0
    while heap:
        value, array_index, element_index = heapq.heappop(heap)
        checksum += (merged_index + 1) * (value + CHECKSUM_OFFSET)
        merged_index += 1
        next_index = element_index + 1
        if next_index < len(arrays[array_index]):
            heapq.heappush(heap, (arrays[array_index][next_index], array_index, next_index))
    return checksum
