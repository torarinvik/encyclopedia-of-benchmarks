"""Independent oracle for the bounded Java Searcher worker kernel."""

from __future__ import annotations

from collections.abc import Sequence

MAX_COUNT = 64
MAX_VALID_INPUT_LENGTH = MAX_COUNT + 4
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1


def expected_result(
    values: Sequence[int] | None,
    input_length: int | None = None,
    input_is_null: bool = False,
) -> int:
    if type(input_is_null) is not bool:
        return INVALID_RESULT
    if input_is_null:
        if ((values is not None and values != [] and values != ())
                or type(input_length) is not int
                or not 1 <= input_length <= MAX_INPUT_LENGTH):
            return INVALID_RESULT
        return INVALID_RESULT
    if values is None:
        return INVALID_RESULT
    if (not isinstance(values, (list, tuple)) or len(values) < 4
            or len(values) > MAX_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT

    count, left, right, target = values[:4]
    if (not 1 <= count <= MAX_COUNT or len(values) != count + 4
            or not 0 <= left <= right <= count
            or not I32_MIN <= target <= I32_MAX):
        return INVALID_RESULT
    items = values[4:]
    if any(not I32_MIN <= item <= I32_MAX for item in items):
        return INVALID_RESULT
    for index in range(left, right):
        if items[index] == target:
            return 1
    return 0
