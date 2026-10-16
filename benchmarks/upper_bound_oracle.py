"""Independent linear oracle for the Java upper-bound boundary behavior."""

from __future__ import annotations

INT32_MIN = -(2**31)
INT32_MAX = 2**31 - 1
MAX_ARRAY_LENGTH = 512
MAX_VALID_INPUT_LENGTH = MAX_ARRAY_LENGTH + 1
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list)
            or not 1 <= len(values) <= MAX_VALID_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT

    target, *array = values
    if not INT32_MIN <= target <= INT32_MAX:
        return INVALID_RESULT
    if (any(not INT32_MIN <= value <= INT32_MAX for value in array)
            or any(array[index - 1] > array[index]
                   for index in range(1, len(array)))):
        return INVALID_RESULT

    for index, value in enumerate(array):
        if target < value:
            return index
    return 0 if not array else len(array) - 1
