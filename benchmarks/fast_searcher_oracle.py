"""Independent oracle for the bounded FastSearcher contract."""

from __future__ import annotations

MAX_ARRAY_LENGTH = 64
MAX_PARSEABLE_ARRAY_LENGTH = 65
MAX_INPUT_LENGTH = MAX_PARSEABLE_ARRAY_LENGTH + 2
MIN_VALUE = -1000
MAX_VALUE = 1000
INVALID_RESULT = -2
NOT_FOUND_RESULT = -1


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   for value in values)):
        return INVALID_RESULT

    count = values[0]
    if not 0 <= count <= MAX_ARRAY_LENGTH or len(values) != count + 2:
        return INVALID_RESULT
    array = values[1:1 + count]
    target = values[-1]
    if (not MIN_VALUE <= target <= MAX_VALUE
            or any(not MIN_VALUE <= value <= MAX_VALUE for value in array)
            or any(array[index - 1] >= array[index] for index in range(1, count))):
        return INVALID_RESULT

    for index, value in enumerate(array):
        if value == target:
            return index
    return NOT_FOUND_RESULT
