"""Oracle for the bounded pinned merge_sorted_arrays routine."""

from __future__ import annotations

MAX_ARRAY_LENGTH = 64
MIN_VALUE = -1_000_000
MAX_VALUE = 1_000_000
CHECKSUM_OFFSET = 1_000_001
MAX_INPUT_LENGTH = 2 + 2 * MAX_ARRAY_LENGTH
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
INVALID_RESULT = -1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the merged-array weighted checksum or INVALID_RESULT."""
    if (not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   for value in values)):
        return INVALID_RESULT

    left_count, right_count = values[0], values[1]
    if (not 0 <= left_count <= MAX_ARRAY_LENGTH
            or not 0 <= right_count <= MAX_ARRAY_LENGTH
            or len(values) != 2 + left_count + right_count):
        return INVALID_RESULT

    left = values[2:2 + left_count]
    right = values[2 + left_count:]
    if any(not MIN_VALUE <= value <= MAX_VALUE for value in (*left, *right)):
        return INVALID_RESULT
    if any(left[index - 1] > left[index] for index in range(1, len(left))):
        return INVALID_RESULT
    if any(right[index - 1] > right[index] for index in range(1, len(right))):
        return INVALID_RESULT

    left_index = right_index = output_index = 0
    checksum = 0
    while left_index < len(left) and right_index < len(right):
        if left[left_index] <= right[right_index]:
            value = left[left_index]
            left_index += 1
        else:
            value = right[right_index]
            right_index += 1
        checksum += (output_index + 1) * (value + CHECKSUM_OFFSET)
        output_index += 1
    while left_index < len(left):
        checksum += (output_index + 1) * (left[left_index] + CHECKSUM_OFFSET)
        left_index += 1
        output_index += 1
    while right_index < len(right):
        checksum += (output_index + 1) * (right[right_index] + CHECKSUM_OFFSET)
        right_index += 1
        output_index += 1
    return checksum
